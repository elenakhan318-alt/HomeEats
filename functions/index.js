const {
  onDocumentWritten,
} = require("firebase-functions/v2/firestore");

const {
  onCall,
  onRequest,
  HttpsError,
} = require("firebase-functions/v2/https");

const {
  defineSecret,
} = require("firebase-functions/params");

const {
  initializeApp,
} = require("firebase-admin/app");

const {
  getFirestore,
  FieldValue,
} = require("firebase-admin/firestore");

initializeApp();

const stripeSecretKey =
  defineSecret("STRIPE_SECRET_KEY");

const stripeWebhookSecret =
  defineSecret("STRIPE_WEBHOOK_SECRET");

const resendApiKey =
  defineSecret("RESEND_API_KEY");

const HOME_EATS_ADMIN_EMAIL =
  "homeeats6@gmail.com";

exports.createStripeCheckoutSession = onCall(
    {
      region: "europe-west1",
      secrets: [stripeSecretKey],
    },
    async (request) => {
      if (!request.auth) {
        throw new HttpsError(
            "unauthenticated",
            "You must be signed in to make a payment.",
        );
      }

      const orderId = String(
          request.data.orderId || "",
      ).trim();

      const successUrl = String(
          request.data.successUrl || "",
      ).trim();

      const cancelUrl = String(
          request.data.cancelUrl || "",
      ).trim();

      if (!orderId) {
        throw new HttpsError(
            "invalid-argument",
            "The order ID is required.",
        );
      }

      validateReturnUrl(successUrl);
      validateReturnUrl(cancelUrl);

      const db = getFirestore();

      const orderReference = db
          .collection("orders")
          .doc(orderId);

      const orderSnapshot =
        await orderReference.get();

      if (!orderSnapshot.exists) {
        throw new HttpsError(
            "not-found",
            "The order could not be found.",
        );
      }

      const orderData =
        orderSnapshot.data() || {};

      if (
        orderData.customerId !==
        request.auth.uid
      ) {
        throw new HttpsError(
            "permission-denied",
            "This order does not belong to you.",
        );
      }

      if (
        orderData.status !==
          "awaiting_payment" ||
        orderData.paymentStatus !==
          "awaiting_payment"
      ) {
        throw new HttpsError(
            "failed-precondition",
            "This order is not awaiting payment.",
        );
      }

      const items = Array.isArray(
          orderData.items,
      ) ?
        orderData.items :
        [];

      if (items.length === 0) {
        throw new HttpsError(
            "failed-precondition",
            "The order does not contain any meals.",
        );
      }

      const fulfilmentType = String(
          orderData.fulfilmentType || "",
      )
          .trim()
          .toLowerCase();

      if (
        fulfilmentType !== "delivery" &&
        fulfilmentType !== "collection"
      ) {
        throw new HttpsError(
            "failed-precondition",
            "The fulfilment method is invalid.",
        );
      }

      const quantitiesByMealId =
        new Map();

      for (const item of items) {
        const mealId = String(
            item.mealId || "",
        ).trim();

        const quantity = Number(
            item.quantity || 0,
        );

        if (
          !mealId ||
          !Number.isInteger(quantity) ||
          quantity <= 0
        ) {
          throw new HttpsError(
              "failed-precondition",
              "The order contains an invalid meal.",
          );
        }

        const currentQuantity =
          quantitiesByMealId.get(mealId) || 0;

        quantitiesByMealId.set(
            mealId,
            currentQuantity + quantity,
        );
      }

      const mealEntries = [
        ...quantitiesByMealId.entries(),
      ];

      const mealReferences =
        mealEntries.map(
            ([mealId]) =>
              db
                  .collection("meals")
                  .doc(mealId),
        );

      const mealSnapshots =
        await db.getAll(
            ...mealReferences,
        );

      let subtotalPence = 0;

      for (
        let index = 0;
        index < mealSnapshots.length;
        index++
      ) {
        const mealSnapshot =
          mealSnapshots[index];

        const [
          ,
          quantityOrdered,
        ] = mealEntries[index];

        if (!mealSnapshot.exists) {
          throw new HttpsError(
              "failed-precondition",
              "A meal is no longer available.",
          );
        }

        const mealData =
          mealSnapshot.data() || {};

        const price = Number(
            mealData.price,
        );

        if (
          !Number.isFinite(price) ||
          price <= 0
        ) {
          throw new HttpsError(
              "failed-precondition",
              "A meal has an invalid price.",
          );
        }

        const remainingValue =
          mealData.remainingPortions !==
              undefined &&
          mealData.remainingPortions !== null ?
            mealData.remainingPortions :
            mealData.portions;

        const remainingPortions =
          Number(remainingValue || 0);

        if (
          !Number.isFinite(
              remainingPortions,
          ) ||
          remainingPortions <
            quantityOrdered
        ) {
          throw new HttpsError(
              "failed-precondition",
              "There are not enough portions available.",
          );
        }

        if (
          fulfilmentType === "delivery" &&
          mealData.deliveryAvailable !== true
        ) {
          throw new HttpsError(
              "failed-precondition",
              "A meal is not available for delivery.",
          );
        }

        if (
          fulfilmentType === "collection" &&
          mealData.collectionAvailable !== true
        ) {
          throw new HttpsError(
              "failed-precondition",
              "A meal is not available for collection.",
          );
        }

        const unitPricePence =
          Math.round(price * 100);

        subtotalPence +=
          unitPricePence *
          quantityOrdered;
      }

      const deliveryFeePence =
        fulfilmentType === "delivery" ?
          250 :
          0;

      const amount =
        subtotalPence +
        deliveryFeePence;

      if (
        !Number.isInteger(amount) ||
        amount < 50
      ) {
        throw new HttpsError(
            "failed-precondition",
            "The calculated order total is invalid.",
        );
      }

      const customerEmail = String(
          request.auth.token.email ||
          orderData.customerEmail ||
          "",
      ).trim();

      const stripe =
        require("stripe")(
            stripeSecretKey.value(),
        );

      try {
        const session =
          await stripe
              .checkout
              .sessions
              .create({
                mode: "payment",

                payment_method_types: [
                  "card",
                ],

                customer_email:
                  customerEmail ||
                  undefined,

                client_reference_id:
                  orderId,

                line_items: [
                  {
                    quantity: 1,

                    price_data: {
                      currency: "gbp",

                      unit_amount:
                        amount,

                      product_data: {
                        name:
                          `HomeEats order ${orderId}`,

                        description:
                          "Payment for a HomeEats food order.",
                      },
                    },
                  },
                ],

                metadata: {
                  orderId,

                  customerId:
                    request.auth.uid,
                },

                payment_intent_data: {
                  metadata: {
                    orderId,

                    customerId:
                      request.auth.uid,
                  },
                },

                success_url:
                  `${successUrl}` +
                  "?session_id=" +
                  "{CHECKOUT_SESSION_ID}",

                cancel_url:
                  cancelUrl,
              });

        if (!session.url) {
          throw new Error(
              "Stripe did not return a checkout URL.",
          );
        }

        await orderReference.set(
            {
              subtotal:
                subtotalPence / 100,

              deliveryFee:
                deliveryFeePence / 100,

              total:
                amount / 100,

              stripeCheckoutSessionId:
                session.id,

              paymentStatus:
                "awaiting_payment",

              updatedAt:
                FieldValue.serverTimestamp(),
            },
            {
              merge: true,
            },
        );

        return {
          checkoutUrl:
            session.url,

          sessionId:
            session.id,
        };
      } catch (error) {
        console.error(
            "Stripe Checkout Session error:",
            error,
        );

        throw new HttpsError(
            "internal",
            "The payment page could not be created.",
        );
      }
    },
);
exports.stripeWebhook = onRequest(
    {
      region: "europe-west1",

      secrets: [
        stripeSecretKey,
        stripeWebhookSecret,
      ],
    },
    async (request, response) => {
      if (request.method !== "POST") {
        response
            .status(405)
            .send(
                "Method not allowed",
            );

        return;
      }

      const stripe =
        require("stripe")(
            stripeSecretKey.value(),
        );

      const signature =
        request.headers[
            "stripe-signature"
        ];

      if (!signature) {
        response
            .status(400)
            .send(
                "Missing Stripe signature",
            );

        return;
      }

      let event;

      try {
        event =
          stripe.webhooks
              .constructEvent(
                  request.rawBody,
                  signature,
                  stripeWebhookSecret
                      .value(),
              );
      } catch (error) {
        console.error(
            "Webhook signature verification failed:",
            error,
        );

        response
            .status(400)
            .send(
                "Invalid webhook signature",
            );

        return;
      }

      try {
        if (
          event.type ===
          "checkout.session.completed"
        ) {
          const session =
            event.data.object;

          let orderId = "";

          if (
            session.metadata &&
            session.metadata.orderId
          ) {
            orderId =
              String(
                  session
                      .metadata
                      .orderId,
              ).trim();
          } else if (
            session
                .client_reference_id
          ) {
            orderId =
              String(
                  session
                      .client_reference_id,
              ).trim();
          }

          if (!orderId) {
            throw new Error(
                "Stripe session has no order ID.",
            );
          }

          if (
            session.payment_status !==
            "paid"
          ) {
            console.log(
                "Checkout completed but payment is not paid:",
                session.id,
            );

            response
                .status(200)
                .send(
                    "Payment not yet paid",
                );

            return;
          }

          let paymentIntentId = "";

          if (
            typeof session
                .payment_intent ===
            "string"
          ) {
            paymentIntentId =
              session.payment_intent;
          } else if (
            session.payment_intent &&
            session
                .payment_intent.id
          ) {
            paymentIntentId =
              session
                  .payment_intent
                  .id;
          }

          const db =
            getFirestore();

          const businessSettingsSnapshot =
            await db
                .collection(
                    "settings",
                )
                .doc("business")
                .get();

          const businessSettings =
            businessSettingsSnapshot
                .data() || {};

          const commissionPercentValue =
            Number(
                businessSettings
                    .commissionPercent,
            );

          const commissionPercent =
            Number.isFinite(
                commissionPercentValue,
            ) &&
            commissionPercentValue >=
              0 &&
            commissionPercentValue <=
              100 ?
              commissionPercentValue :
              10;

          const totalPaidPence =
            Number(
                session.amount_total ||
                0,
            );

          const platformCommissionPence =
            Math.round(
                totalPaidPence *
                (
                  commissionPercent /
                  100
                ),
            );

          const cookGrossEarningsPence =
            totalPaidPence -
            platformCommissionPence;

          const orderReference =
            db
                .collection("orders")
                .doc(orderId);

          const transactionResult =
            await db.runTransaction(
                async (
                    transaction,
                ) => {
                  const orderSnapshot =
                    await transaction
                        .get(
                            orderReference,
                        );

                  if (
                    !orderSnapshot
                        .exists
                  ) {
                    throw new Error(
                        `Order ${orderId} does not exist.`,
                    );
                  }

                  const orderData =
                    orderSnapshot
                        .data() || {};

                  const cookIds =
                    Array.isArray(
                        orderData
                            .cookIds,
                    ) ?
                      orderData
                          .cookIds :
                      [];

                  if (
                    orderData
                        .stockProcessed ===
                    true
                  ) {
                    return {
                      alreadyProcessed:
                        true,
                      cookIds,
                    };
                  }

                  const items =
                    Array.isArray(
                        orderData.items,
                    ) ?
                      orderData.items :
                      [];

                  if (
                    items.length === 0
                  ) {
                    throw new Error(
                        `Order ${orderId} has no items.`,
                    );
                  }

                  const quantitiesByMealId =
                    new Map();

                  for (
                    const item of
                    items
                  ) {
                    const mealId =
                      String(
                          item.mealId ||
                          "",
                      ).trim();

                    const quantity =
                      Number(
                          item.quantity ||
                          0,
                      );

                    if (
                      !mealId ||
                      !Number.isInteger(
                          quantity,
                      ) ||
                      quantity <= 0
                    ) {
                      throw new Error(
                          `Order ${orderId} contains an invalid meal item.`,
                      );
                    }

                    const currentQuantity =
                      quantitiesByMealId
                          .get(
                              mealId,
                          ) || 0;

                    quantitiesByMealId
                        .set(
                            mealId,
                            currentQuantity +
                              quantity,
                        );
                  }

                  const mealEntries =
                    [
                      ...quantitiesByMealId
                          .entries(),
                    ];

                  const mealReferences =
                    mealEntries.map(
                        ([mealId]) =>
                          db
                              .collection(
                                  "meals",
                              )
                              .doc(
                                  mealId,
                              ),
                    );
                  const mealSnapshots =
                    await transaction
                        .getAll(
                            ...mealReferences,
                        );

                  for (
                    let index = 0;
                    index <
                      mealSnapshots.length;
                    index++
                  ) {
                    const mealSnapshot =
                      mealSnapshots[index];

                    const [
                      mealId,
                      quantityOrdered,
                    ] =
                      mealEntries[index];

                    if (
                      !mealSnapshot.exists
                    ) {
                      throw new Error(
                          `Meal ${mealId} does not exist.`,
                      );
                    }

                    const mealData =
                      mealSnapshot
                          .data() || {};

                    const remainingPortionsValue =
                      mealData
                          .remainingPortions !==
                        undefined &&
                      mealData
                          .remainingPortions !==
                        null ?
                        mealData
                            .remainingPortions :
                        mealData.portions;

                    const remainingPortions =
                      Number(
                          remainingPortionsValue ||
                          0,
                      );

                    if (
                      !Number.isFinite(
                          remainingPortions,
                      ) ||
                      remainingPortions <
                        quantityOrdered
                    ) {
                      throw new Error(
                          `Not enough portions for meal ${mealId}.`,
                      );
                    }
                  }

                  for (
                    let index = 0;
                    index <
                      mealSnapshots.length;
                    index++
                  ) {
                    const mealSnapshot =
                      mealSnapshots[index];

                    const [
                      ,
                      quantityOrdered,
                    ] =
                      mealEntries[index];

                    const mealData =
                      mealSnapshot
                          .data() || {};

                    const remainingPortionsValue =
                      mealData
                          .remainingPortions !==
                        undefined &&
                      mealData
                          .remainingPortions !==
                        null ?
                        mealData
                            .remainingPortions :
                        mealData.portions;

                    const remainingPortions =
                      Number(
                          remainingPortionsValue ||
                          0,
                      );

                    const newRemainingPortions =
                      remainingPortions -
                      quantityOrdered;

                    const mealUpdates = {
                      remainingPortions:
                        newRemainingPortions,

                      updatedAt:
                        FieldValue
                            .serverTimestamp(),
                    };

                    if (
                      newRemainingPortions ===
                      0
                    ) {
                      mealUpdates.status =
                        "sold_out";

                      mealUpdates.active =
                        false;
                    }

                    transaction.update(
                        mealSnapshot.ref,
                        mealUpdates,
                    );
                  }

                  transaction.set(
                      orderReference,
                      {
                        status:
                          "pending",

                        paymentStatus:
                          "paid",

                        stripeCheckoutSessionId:
                          session.id,

                        stripePaymentIntentId:
                          paymentIntentId,

                        stripeWebhookEventId:
                          event.id,

                        totalPaidPence:
                          totalPaidPence,

                        totalPaid:
                          totalPaidPence /
                          100,

                        currency:
                          session.currency ||
                          "gbp",

                        commissionPercent:
                          commissionPercent,

                        platformCommissionPence:
                          platformCommissionPence,

                        platformCommission:
                          platformCommissionPence /
                          100,

                        cookGrossEarningsPence:
                          cookGrossEarningsPence,

                        cookGrossEarnings:
                          cookGrossEarningsPence /
                          100,

                        stockProcessed:
                          true,

                        stockProcessedAt:
                          FieldValue
                              .serverTimestamp(),

                        paidAt:
                          FieldValue
                              .serverTimestamp(),

                        updatedAt:
                          FieldValue
                              .serverTimestamp(),
                      },
                      {
                        merge: true,
                      },
                  );

                  return {
                    alreadyProcessed:
                      false,

                    cookIds,
                  };
                },
            );

          for (
            const cookId of
            transactionResult.cookIds
          ) {
            const notificationId =
              `paid_${orderId}_${cookId}`;

            await db
                .collection(
                    "notifications",
                )
                .doc(
                    notificationId,
                )
                .set(
                    {
                      userId:
                        cookId,

                      orderId,

                      title:
                        "New paid order",

                      message:
                        "A new paid order is waiting for you.",

                      isRead:
                        false,

                      createdAt:
                        FieldValue
                            .serverTimestamp(),
                    },
                    {
                      merge: true,
                    },
                );
          }

          if (
            transactionResult
                .alreadyProcessed
          ) {
            console.log(
                `Order ${orderId} was already processed.`,
            );
          } else {
            console.log(
                `Order ${orderId} marked as paid and stock updated.`,
            );
          }
        }

        response
            .status(200)
            .send("Received");
      } catch (error) {
        console.error(
            "Stripe webhook processing error:",
            error,
        );

        response
            .status(500)
            .send(
                "Webhook processing failed",
            );
      }
    },
);
/*
 * Automatically refund paid orders rejected by a cook.
 */
exports.refundRejectedOrder = onDocumentWritten(
    {
      document: "orders/{orderId}",
      region: "europe-west1",
      secrets: [stripeSecretKey],
    },
    async (event) => {
      const beforeSnapshot = event.data.before;
      const afterSnapshot = event.data.after;

      if (!afterSnapshot.exists) {
        return;
      }

      const beforeData = beforeSnapshot.exists ?
        beforeSnapshot.data() :
        {};

      const afterData = afterSnapshot.data() || {};

      const oldStatus = String(
          beforeData.status || "",
      )
          .trim()
          .toLowerCase();

      const newStatus = String(
          afterData.status || "",
      )
          .trim()
          .toLowerCase();

      /*
       * Only run when an order actually changes
       * from another status to rejected.
       */
      if (
        newStatus !== "rejected" ||
        oldStatus === "rejected"
      ) {
        return;
      }

      const paymentStatus = String(
          afterData.paymentStatus || "",
      )
          .trim()
          .toLowerCase();

      if (paymentStatus !== "paid") {
        console.log(
            "Rejected order was not paid:",
            event.params.orderId,
        );
        return;
      }

      const paymentIntentId = String(
          afterData.stripePaymentIntentId || "",
      ).trim();

      if (!paymentIntentId) {
        console.error(
            "Rejected paid order has no Stripe PaymentIntent:",
            event.params.orderId,
        );

        await afterSnapshot.ref.set(
            {
              refundStatus: "failed",
              refundError:
                "Missing Stripe PaymentIntent ID.",
              refundUpdatedAt:
                FieldValue.serverTimestamp(),
            },
            {
              merge: true,
            },
        );

        return;
      }

      const orderId = event.params.orderId;

      const stripe = require("stripe")(
          stripeSecretKey.value(),
      );

      try {
        /*
         * Stripe idempotency prevents the same
         * order being refunded twice.
         */
        const refund =
          await stripe.refunds.create(
              {
                payment_intent:
                  paymentIntentId,
              },
              {
                idempotencyKey:
                  `homeeats-rejection-${orderId}`,
              },
          );

        const db = getFirestore();

        await db.runTransaction(
            async (transaction) => {
              const orderSnapshot =
                await transaction.get(
                    afterSnapshot.ref,
                );

              if (!orderSnapshot.exists) {
                throw new Error(
                    `Order ${orderId} no longer exists.`,
                );
              }

              const orderData =
                orderSnapshot.data() || {};

              /*
               * Restore stock only once.
               */
              if (
                orderData.stockProcessed === true &&
                orderData.stockRestored !== true
              ) {
                const items =
                  Array.isArray(orderData.items) ?
                    orderData.items :
                    [];

                const quantitiesByMealId =
                  new Map();

                for (const item of items) {
                  const mealId = String(
                      item.mealId || "",
                  ).trim();

                  const quantity = Number(
                      item.quantity || 0,
                  );

                  if (
                    !mealId ||
                    !Number.isInteger(quantity) ||
                    quantity <= 0
                  ) {
                    continue;
                  }

                  const currentQuantity =
                    quantitiesByMealId.get(
                        mealId,
                    ) || 0;

                  quantitiesByMealId.set(
                      mealId,
                      currentQuantity + quantity,
                  );
                }

                for (
                  const [
                    mealId,
                    quantity,
                  ] of quantitiesByMealId
                ) {
                  const mealReference =
                    db
                        .collection("meals")
                        .doc(mealId);

                  const mealSnapshot =
                    await transaction.get(
                        mealReference,
                    );

                  if (!mealSnapshot.exists) {
                    continue;
                  }

                  const mealData =
                    mealSnapshot.data() || {};

                  const remainingValue =
  mealData.remainingPortions !==
      undefined &&
  mealData.remainingPortions !==
      null ?
    mealData.remainingPortions :
    mealData.portions;

                  const currentRemaining =
  Number(
      remainingValue || 0,
  );

                  const restoredRemaining =
                    currentRemaining + quantity;

                  const mealUpdates = {
                    remainingPortions:
                      restoredRemaining,

                    updatedAt:
                      FieldValue.serverTimestamp(),
                  };

                  if (
                    String(
                        mealData.status || "",
                    ).toLowerCase() ===
                    "sold_out"
                  ) {
                    mealUpdates.status =
                      "available";

                    mealUpdates.active =
                      true;
                  }

                  transaction.update(
                      mealReference,
                      mealUpdates,
                  );
                }
              }

              transaction.set(
                  afterSnapshot.ref,
                  {
                    refundStatus:
                      refund.status ||
                      "pending",

                    stripeRefundId:
                      refund.id,

                    refundedAmountPence:
                      refund.amount,

                    refundedAmount:
                      refund.amount / 100,

                    refundReason:
                      "cook_rejected",

                    refundRequestedAt:
                      FieldValue.serverTimestamp(),

                    stockRestored:
                      true,

                    stockRestoredAt:
                      FieldValue.serverTimestamp(),

                    updatedAt:
                      FieldValue.serverTimestamp(),
                  },
                  {
                    merge: true,
                  },
              );
            },
        );

        console.log(
            `Refund ${refund.id} created for rejected order ${orderId}.`,
        );
      } catch (error) {
        console.error(
            `Refund failed for order ${orderId}:`,
            error,
        );

        await afterSnapshot.ref.set(
            {
              refundStatus: "failed",

              refundError:
                error.message ||
                "Stripe refund failed.",

              refundUpdatedAt:
                FieldValue.serverTimestamp(),

              updatedAt:
                FieldValue.serverTimestamp(),
            },
            {
              merge: true,
            },
        );
      }
    },
);
/*
 * Cook verification email notifications
 */

exports.sendCookVerificationEmails =
  onDocumentWritten(
      {
        document:
          "cookApplications/{cookId}",

        region:
          "europe-west1",

        secrets:
          [resendApiKey],
      },
      async (event) => {
        const beforeSnapshot =
          event.data.before;

        const afterSnapshot =
          event.data.after;

        if (!afterSnapshot.exists) {
          return;
        }

        const beforeData =
          beforeSnapshot.exists ?
            beforeSnapshot.data() :
            {};

        const afterData =
          afterSnapshot.data() || {};

        const oldStatus =
          String(
              beforeData
                  .verificationStatus ||
              "",
          )
              .trim()
              .toLowerCase();

        const newStatus =
          String(
              afterData
                  .verificationStatus ||
              "",
          )
              .trim()
              .toLowerCase();

        if (
          !newStatus ||
          oldStatus === newStatus
        ) {
          return;
        }

        const cookId =
          event.params.cookId;

        const db =
          getFirestore();

        const userSnapshot =
          await db
              .collection("users")
              .doc(cookId)
              .get();

        const userData =
          userSnapshot.exists ?
            userSnapshot.data() ||
              {} :
            {};

        const cookEmail =
          String(
              userData.email ||
              afterData.email ||
              "",
          ).trim();

        const cookName =
          String(
              userData.fullName ||
              afterData.businessName ||
              "Cook",
          ).trim();

        const reviewNotes =
          String(
              afterData.reviewNotes ||
              "",
          ).trim();

        if (
          newStatus ===
          "awaiting_contact"
        ) {
          await sendHomeEatsEmail({
            to:
              HOME_EATS_ADMIN_EMAIL,

            subject:
              "New HomeEats cook awaiting contact",

            html: `
              <h2>New cook application</h2>
              <p>
                <strong>
                  ${escapeHtml(cookName)}
                </strong>
                has submitted their initial
                HomeEats cook application.
              </p>
              <p>
                Please open the HomeEats Admin
                dashboard and contact the cook
                before unlocking documents.
              </p>
            `,
          });

          return;
        }

        if (
          newStatus ===
          "documents_required"
        ) {
          if (!cookEmail) {
            console.warn(
                "Cook email missing:",
                cookId,
            );
            return;
          }

          await sendHomeEatsEmail({
            to:
              cookEmail,

            subject:
              "Your HomeEats document uploads are ready",

            html: `
              <h2>
                Hi ${escapeHtml(cookName)},
              </h2>
              <p>
                You can now sign in to HomeEats
                and upload your required
                verification documents.
              </p>
            `,
          });

          return;
        }

        if (
          newStatus === "pending"
        ) {
          await sendHomeEatsEmail({
            to:
              HOME_EATS_ADMIN_EMAIL,

            subject:
              "HomeEats cook verification ready for review",

            html: `
              <h2>
                Cook verification submitted
              </h2>
              <p>
                <strong>
                  ${escapeHtml(cookName)}
                </strong>
                has submitted their verification
                documents and is waiting for
                review.
              </p>
            `,
          });

          return;
        }

        if (
          newStatus ===
          "changes_requested"
        ) {
          if (!cookEmail) {
            return;
          }

          await sendHomeEatsEmail({
            to:
              cookEmail,

            subject:
              "Changes requested for your HomeEats application",

            html: `
              <h2>
                Hi ${escapeHtml(cookName)},
              </h2>
              <p>
                An administrator has requested
                changes to your HomeEats cook
                application.
              </p>
              ${
                reviewNotes ?
                  `
                    <p>
                      <strong>Review notes:</strong>
                    </p>
                    <p>
                      ${escapeHtml(reviewNotes)}
                    </p>
                  ` :
                  ""
}
              <p>
                Please sign in, make the
                requested changes and resubmit
                your application.
              </p>
            `,
          });

          return;
        }

        if (
          newStatus ===
          "approved"
        ) {
          if (!cookEmail) {
            return;
          }

          await sendHomeEatsEmail({
            to:
              cookEmail,

            subject:
              "Your HomeEats cook account has been approved",

            html: `
              <h2>
                Congratulations
                ${escapeHtml(cookName)}!
              </h2>
              <p>
                Your HomeEats cook verification
                has been approved.
              </p>
              <p>
                You can now access your
                Cook Dashboard.
              </p>
            `,
          });

          return;
        }

        if (
          newStatus ===
          "rejected"
        ) {
          if (!cookEmail) {
            return;
          }

          await sendHomeEatsEmail({
            to:
              cookEmail,

            subject:
              "Update on your HomeEats cook application",

            html: `
              <h2>
                Hi ${escapeHtml(cookName)},
              </h2>
              <p>
                Your HomeEats cook application
                was not approved at this stage.
              </p>
              ${
                reviewNotes ?
                  `
                    <p>
                      <strong>Review notes:</strong>
                    </p>
                    <p>
                      ${escapeHtml(reviewNotes)}
                    </p>
                  ` :
                  ""
}
            `,
          });
        }
      },
  );
exports.updateRatingSummaries = onDocumentWritten(
    {
      document: "ratings/{ratingId}",
      region: "europe-west1",
    },
    async (event) => {
      const beforeSnapshot =
        event.data.before;

      const afterSnapshot =
        event.data.after;

      const beforeData =
        beforeSnapshot.exists ?
          beforeSnapshot.data() :
          null;

      const afterData =
        afterSnapshot.exists ?
          afterSnapshot.data() :
          null;

      const cookIds = new Set();
      const mealIds = new Set();

      if (beforeData) {
        if (beforeData.cookId) {
          cookIds.add(
              String(beforeData.cookId),
          );
        }

        if (beforeData.mealId) {
          mealIds.add(
              String(beforeData.mealId),
          );
        }
      }

      if (afterData) {
        if (afterData.cookId) {
          cookIds.add(
              String(afterData.cookId),
          );
        }

        if (afterData.mealId) {
          mealIds.add(
              String(afterData.mealId),
          );
        }
      }

      const db =
        getFirestore();

      for (const cookId of cookIds) {
        const snapshot =
          await db
              .collection("ratings")
              .where(
                  "cookId",
                  "==",
                  cookId,
              )
              .where(
                  "status",
                  "==",
                  "published",
              )
              .get();

        let total = 0;

        for (
          const document of
          snapshot.docs
        ) {
          const value =
            Number(
                document
                    .data()
                    .rating ||
                0,
            );

          if (
            Number.isFinite(value)
          ) {
            total += value;
          }
        }

        const reviewCount =
          snapshot.docs.length;

        const averageRating =
          reviewCount === 0 ?
            0 :
            total / reviewCount;

        const cookReference =
          db
              .collection("users")
              .doc(cookId);

        const cookSnapshot =
          await cookReference.get();

        if (
          cookSnapshot.exists
        ) {
          await cookReference
              .update({
                averageRating,

                reviewCount,

                ratingsUpdatedAt:
                  FieldValue
                      .serverTimestamp(),
              });
        }
      }

      for (
        const mealId of mealIds
      ) {
        const snapshot =
          await db
              .collection("ratings")
              .where(
                  "mealId",
                  "==",
                  mealId,
              )
              .where(
                  "status",
                  "==",
                  "published",
              )
              .get();

        let total = 0;

        for (
          const document of
          snapshot.docs
        ) {
          const value =
            Number(
                document
                    .data()
                    .rating ||
                0,
            );

          if (
            Number.isFinite(value)
          ) {
            total += value;
          }
        }

        const reviewCount =
          snapshot.docs.length;

        const averageRating =
          reviewCount === 0 ?
            0 :
            total / reviewCount;

        const mealReference =
          db
              .collection("meals")
              .doc(mealId);

        const mealSnapshot =
          await mealReference.get();

        if (
          mealSnapshot.exists
        ) {
          await mealReference
              .update({
                averageRating,

                reviewCount,

                ratingsUpdatedAt:
                  FieldValue
                      .serverTimestamp(),
              });
        }
      }

      console.log(
          "Rating summaries updated.",
          {
            ratingId:
              event.params.ratingId,

            cookIds:
              [...cookIds],

            mealIds:
              [...mealIds],
          },
      );
    },
);
/**
 * Sends a HomeEats email through Resend.
 * @param {Object} options Email options.
 * @param {string} options.to Recipient email.
 * @param {string} options.subject Email subject.
 * @param {string} options.html Email body.
 * @return {Promise<void>}
 */
async function sendHomeEatsEmail({
  to,
  subject,
  html,
}) {
  const response =
    await fetch(
        "https://api.resend.com/emails",
        {
          method: "POST",

          headers: {
            "Authorization":
              `Bearer ${resendApiKey.value()}`,

            "Content-Type":
              "application/json",
          },

          body:
            JSON.stringify({
              from:
  "HomeEats <notifications@homeeats.co.uk>",

              to: [to],

              subject,

              html,
            }),
        },
    );

  const responseText =
    await response.text();

  if (!response.ok) {
    console.error(
        "Resend email error:",
        response.status,
        responseText,
    );

    throw new Error(
        `Resend email failed with status ${response.status}.`,
    );
  }

  console.log(
      "HomeEats email sent:",
      {
        to,
        subject,
      },
  );
}
/**
 * Escapes unsafe characters for HTML.
 * @param {string} value Text to escape.
 * @return {string} Escaped HTML text.
 */
function escapeHtml(value) {
  return String(value)
      .replace(
          /&/g,
          "&amp;",
      )
      .replace(
          /</g,
          "&lt;",
      )
      .replace(
          />/g,
          "&gt;",
      )
      .replace(
          /"/g,
          "&quot;",
      )
      .replace(
          /'/g,
          "&#039;",
      );
}
/**
 * Validates an allowed Stripe return URL.
 * @param {string} value URL to validate.
 * @return {void}
 */
function validateReturnUrl(value) {
  let parsedUrl;

  try {
    parsedUrl =
      new URL(value);
  } catch (_) {
    throw new HttpsError(
        "invalid-argument",
        "The payment return URL is invalid.",
    );
  }

  const isSecure =
    parsedUrl.protocol ===
    "https:";

  const isLocal =
    parsedUrl.protocol ===
      "http:" &&
    (
      parsedUrl.hostname ===
        "localhost" ||
      parsedUrl.hostname ===
        "127.0.0.1"
    );

  if (
    !isSecure &&
    !isLocal
  ) {
    throw new HttpsError(
        "invalid-argument",
        "The payment return URL is not allowed.",
    );
  }
}
