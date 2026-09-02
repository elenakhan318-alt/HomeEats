import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import 'basket_data.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final String? orderId;

  const PaymentSuccessScreen({
    super.key,
    this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    final String shortOrderId =
        orderId != null && orderId!.length >= 8
            ? orderId!.substring(0, 8).toUpperCase()
            : 'CONFIRMED';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: Center(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.large),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  AppRadius.card,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(
                      color: AppColors.secondaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.secondaryDark,
                      size: 54,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.large),
                  const Text(
                    'Payment successful!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.small),
                  const Text(
                    'Your payment has been received. '
                    'The cook can now review your order.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.regular),
                  Text(
                    'Order $shortOrderId',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.large),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        basketData.clearBasket();

                        Navigator.of(context).popUntil(
                          (route) => route.isFirst,
                        );
                      },
                      child: const Text(
                        'Return to Home',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}