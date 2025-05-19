const functions = require("firebase-functions");
const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

exports.sendMissedCallNotification = onDocumentUpdated(
  "calls/{callId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    if (
      before.status !== "ended" &&
      after.status === "ended" &&
      !after.accepted &&
      after.receiverUid // Make sure we have a receiver to notify
    ) {
      const receiverUid = after.receiverUid;
      const callerName = after.callerName || "Someone";
      const callType = after.callType || "voice";
      const callId = event.params.callId; 

      // Get receiver's FCM token
      const userDoc = await getFirestore()
        .collection("users")
        .doc(receiverUid)
        .get();

      if (!userDoc.exists) {
        console.log("Receiver document not found:", receiverUid);
        return;
      }

      const fcmToken = userDoc.data().fcmToken;
      if (!fcmToken) {
        console.log("No FCM token found for receiver:", receiverUid);
        return;
      }

    
      const defaultImage =
        "https://th.bing.com/th/id/OIP.SAcV4rjQCseubnk32USHigHaHx?rs=1&pid=ImgDetMain";
      let callerImage = "";
      try {
        const callerDoc = await getFirestore()
          .collection("users")
          .doc(after.callerUid)
          .get();
        callerImage = callerDoc.data()?.profileImage || defaultImage;
      } catch (e) {
        console.error("Error fetching caller image:", e);
        callerImage = defaultImage;
      }

    
      try {
        const callLogData = {
          ...after,
          status: "missed", 
          timestamp: new Date().toISOString(),
          accepted: false,
        };

        await getFirestore()
          .collection("users")
          .doc(receiverUid)
          .collection("callLogs")
          .doc(callId)
          .set(callLogData);

        console.log("Updated call log for missed call:", callId);
      } catch (error) {
        console.error("Error updating call log:", error);
      }

    
      const message = {
        token: fcmToken,
        notification: {
          title: "Missed Call",
          body:
            after.endReason === "ended_by_caller"
              ? `📞 ${callerName} cancelled their ${callType} call`
              : `📞 Missed ${callType} call from ${callerName}`,
        },
        data: {
          type: "missed_call",
          call_type: callType,
          caller_name: callerName,
          caller_image: callerImage,
          call_id: callId,
          end_reason: after.endReason || "missed",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          timestamp: after.timestamp || new Date().toISOString(),
        },
        android: {
          priority: "high",
          notification: {
            channel_id: "call_channel",
            priority: "max",
            sound: "default",
            default_vibrate_timings: true,
            icon: "@mipmap/ic_launcher",
            color: "#FF0000",
            notification_count: 1,
            visibility: "public",
          },
        },
        apns: {
          headers: {
            "apns-priority": "10",
          },
          payload: {
            aps: {
              sound: "default",
              badge: 1,
              "content-available": 1,
              "mutable-content": 1,
              alert: {
                title: "Missed Call",
                body:
                  after.endReason === "ended_by_caller"
                    ? `${callerName} cancelled their ${callType} call`
                    : `Missed ${callType} call from ${callerName}`,
                "thread-id": "missed_calls",
              },
              category: "missed_call",
            },
            imageUrl: callerImage,
          },
        },
      };

      // Add image to notification if available
      if (callerImage && callerImage !== defaultImage) {
        message.notification.image = callerImage;
      }

      try {
        await getMessaging().send(message);
        console.log(
          "Successfully sent missed call notification to:",
          receiverUid
        );
      } catch (error) {
        console.error("Error sending missed call notification:", error);
      }
    }
  }
);

exports.sendMessageNotification = onDocumentCreated(
  "chats/{roomId}/messages/{messageId}",
  async (event) => {
    const messageData = event.data.data();
    const receiverId = messageData.receiverId;
    const senderName = messageData.senderName || "Someone";
    const roomId = event.params.roomId;

    // Get receiver's FCM token
    const userDoc = await getFirestore()
      .collection("users")
      .doc(receiverId)
      .get();
    const fcmToken = userDoc.data().fcmToken;

    // Get sender's profile image
    let senderImage = "";
    try {
      const senderDoc = await getFirestore()
        .collection("users")
        .doc(messageData.senderId)
        .get();
      senderImage = senderDoc.data().profileImage || "";
    } catch (e) {
      senderImage = "";
    }

    if (fcmToken) {
      const message = {
        token: fcmToken,
        notification: {
          title: senderName,
          body: messageData.message || "You have a new message!",
          image: senderImage || undefined,
        },
        data: {
          type: "chat",
          room_id: roomId,
          sender_id: messageData.senderId,
          sender_image: senderImage,
          sender_name: senderName,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high",
          notification: {
            channel_id: "message_channel",
            priority: "high",
            default_sound: true,
            default_vibrate_timings: true,
            image: senderImage || undefined,
          },
        },
        apns: {
          headers: {
            "apns-priority": "10",
          },
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      };
      try {
        await getMessaging().send(message);
      } catch (error) {
        console.error("Error sending message notification:", error);
      }
    }
  }
);
