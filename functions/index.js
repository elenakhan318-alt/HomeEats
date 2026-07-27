const {onCall} = require("firebase-functions/v2/https");

exports.helloWorld = onCall((request) => {
  return {
    message: "Functions are working!",
  };
});
