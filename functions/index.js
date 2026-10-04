
const {
  onDocumentCreated,
} = require("firebase-functions/v2/firestore");

const {
  initializeApp,
} = require("firebase-admin/app");

const {
  getFirestore,
  FieldValue,
} = require("firebase-admin/firestore");
// const {
//   getFirestore,
// } = require("firebase-admin/firestore");

const {
  getMessaging,
} = require("firebase-admin/messaging");

initializeApp();

const db = getFirestore();

exports.sendChatNotification =
  onDocumentCreated(
    "chats/{chatId}/messages/{messageId}",
    async (event) => {
      const snapshot = event.data;

      if (!snapshot) {
        return;
      }

      const message =
        snapshot.data();

      if (!message) {
        return;
      }

      const senderId =
        message.senderId;

      const receiverId =
        message.receiverId;

      if (!senderId ||
          !receiverId) {
        return;
      }

      // Don't notify the sender.
      if (senderId === receiverId) {
        return;
      }

      const receiverRef =
        db
          .collection("users")
          .doc(receiverId);

      const senderRef =
        db
          .collection("users")
          .doc(senderId);

      const [
        receiverSnapshot,
        senderSnapshot,
      ] = await Promise.all([
        receiverRef.get(),
        senderRef.get(),
      ]);

      if (!receiverSnapshot.exists) {
        return;
      }

      if (!senderSnapshot.exists) {
        return;
      }

      const receiver =
        receiverSnapshot.data();

      const sender =
        senderSnapshot.data();

      if (!receiver ||
          !sender) {
        return;
      }

      // Check user's notification setting.
      const notificationsEnabled =
          receiver.notificationsEnabled !== false;

      if (!notificationsEnabled) {
        console.log(
          "Notifications disabled for:",
          receiverId
        );

        return;
      }

      const tokens =
          Array.isArray(
            receiver.fcmTokens
          )
            ? receiver.fcmTokens
            : [];

      if (tokens.length === 0) {
        console.log(
          "No FCM tokens for:",
          receiverId
        );

        return;
      }

      const senderName =
          sender.name || "Someone";

      const messageText =
          message.text || "";

      const messageType =
          message.type || "text";

      const showMessageContent =
          receiver.showMessageContent !== false;

      let title =
          receiver.notificationTitle ||
          "💬 New Message";

      let body =
          receiver.notificationBody ||
          "{sender} sent you a message";

      title = replaceVariables(
        title,
        senderName,
        messageText,
        messageType
      );

      if (!showMessageContent) {
        body =
          `${senderName} sent you a message`;
      } else {
        body = replaceVariables(
          body,
          senderName,
          messageText,
          messageType
        );
      }

      const chatId =
          event.params.chatId;

      const messageId =
          event.params.messageId;

      const response =
        await getMessaging()
          .sendEachForMulticast({
            tokens,

            notification: {
              title,
              body,
            },

            data: {
              chatId:
                chatId.toString(),

              messageId:
                messageId.toString(),

              senderId:
                senderId.toString(),

              receiverId:
                receiverId.toString(),

              type:
                messageType.toString(),
            },

            android: {
              priority: "high",

              notification: {
                channelId:
                  "chat_messages",

                sound:
                  "default",
              },
            },

            apns: {
              payload: {
                aps: {
                  sound:
                    "default",
                },
              },
            },
          });

      console.log(
        `Notification sent. `
        + `Success: ${response.successCount}, `
        + `Failure: ${response.failureCount}`
      );

      // Remove invalid tokens.
      if (
        response.failureCount > 0
      ) {
        const invalidTokens = [];

        response.responses.forEach(
          (result, index) => {
            if (
              !result.success &&
              result.error
            ) {
              const code =
                result.error.code;

              if (
                code ===
                  "messaging/registration-token-not-registered" ||
                code ===
                  "messaging/invalid-registration-token"
              ) {
                invalidTokens.push(
                  tokens[index]
                );
              }
            }
          }
        );

        if (
          invalidTokens.length > 0
        ) {
          await receiverRef.update({
            fcmTokens:
              FieldValue.arrayRemove(
                    ...invalidTokens
                    )
          });
        }
      }
    }
  );

function replaceVariables(
  text,
  sender,
  message,
  type
) {
  return text
    .replace(
      /\{sender\}/g,
      sender
    )
    .replace(
      /\{message\}/g,
      message
    )
    .replace(
      /\{type\}/g,
      type
    );
}