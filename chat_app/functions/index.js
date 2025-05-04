/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const functions = require("firebase-functions");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

exports.sendCallNotification = onDocumentCreated("calls/{callId}", async (event) => {
  const callData = event.data.data();
  const receiverUid = callData.receiverUid;
  const callId = callData.id;

  console.log("❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️Function triggered for callId:", callId, "receiverUid:", receiverUid);

  // Get receiver's FCM token
  const userDoc = await getFirestore().collection("users").doc(receiverUid).get();
  const fcmToken = userDoc.data().fcmToken;

  console.log("❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️Fetched FCM token:", fcmToken);

  if (fcmToken) {
    const message = {
      token: fcmToken,
      notification: {
        title: "Incoming Call",
        body: `${callData.callerName} is calling you!`,
      },
      data: {
        call_id: callId,
      },
    };
    try {
      const response = await getMessaging().send(message);
      console.log(":❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️✅ Notification response:", JSON.stringify(response));
    } catch (error) {
      console.error("❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❌ Error sending notification:", error);
    }
  } else {
    console.log("❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️No FCM token found for user:", receiverUid);
  }
});
