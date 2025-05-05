const functions = require("firebase-functions");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();
exports.sendCallNotification = onDocumentCreated("calls/{callId}", async (event) => {
  const callData = event.data.data();
  const receiverUid = callData.receiverUid;
  const callId = callData.id;
  const callTypeText = callData.callType === 'video' ? 'video call' : 'voice call';

  console.log("❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️: Function triggered for callId:", callId, "receiverUid:", receiverUid);

  // Get receiver's FCM token
  const userDoc = await getFirestore().collection("users").doc(receiverUid).get();
  const fcmToken = userDoc.data().fcmToken;

  console.log("❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️: Fetched FCM token:", fcmToken);

  if (fcmToken) {
    const message = {
      token: fcmToken,
      notification: {
        title: "Incoming Call",
        body: `${callData.callerName} is calling you (${callTypeText})!`,
        priority: "high"
      },
      data: {
        call_id: callId,
        call_type: callData.callType || 'voice',
      },
      android: {
        priority: "high"
      },
      apns: {
        headers: {
          "apns-priority": "10"
        }
      }
    };
    try {
      const response = await getMessaging().send(message);
      console.log(":❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️✅ : Notification response:", JSON.stringify(response));
    } catch (error) {
      console.error("❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❌: Error sending notification:", error);
    }
  } else {
    console.log("❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️: No FCM token found for user:", receiverUid);
  }
});

exports.sendMessageNotification = onDocumentCreated("chats/{roomId}/messages/{messageId}", async (event) => {
  const messageData = event.data.data();
  const receiverId = messageData.receiverId;
  const senderName = messageData.senderName || "Someone";
  const roomId = event.params.roomId;

  // Get receiver's FCM token
  const userDoc = await getFirestore().collection("users").doc(receiverId).get();
  const fcmToken = userDoc.data().fcmToken;

  if (fcmToken) {
    const message = {
      token: fcmToken,
      notification: {
        title: senderName,
        body: messageData.message || "You have a new message!",
      },
      data: {
        room_id: roomId,
        sender_id: messageData.senderId,
        type: "chat",
      },
      android: {
        priority: "high",
        notification: {
          channel_id: "message_channel",
          click_action: "FLUTTER_NOTIFICATION_CLICK"
        }
      },
      apns: {
        headers: {
          "apns-priority": "10"
        }
      }
    };
    try {
      await getMessaging().send(message);
    } catch (error) {
      console.error("Error sending message notification:", error);
    }
  }
});
