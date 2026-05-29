const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

/**
 * Cloud Function triggered on creation of a new message under conversations subcollection.
 * Resolves recipient user's tokens, sends an FCM notification, and handles expired tokens dynamically.
 */
exports.sendChatNotification = functions.firestore
  .document("conversations/{conversationId}/messages/{messageId}")
  .onCreate(async (snapshot, context) => {
    const message = snapshot.data();
    const conversationId = context.params.conversationId;
    const senderId = message.sender_id;
    const content = message.content;

    console.log(`[FCM Trigger] New message detected in conversation: ${conversationId} from sender: ${senderId}`);

    // 1. Fetch conversation details to locate participants
    const convRef = admin.firestore().collection("conversations").doc(conversationId);
    const convDoc = await convRef.get();
    if (!convDoc.exists) {
      console.log(`[FCM Trigger] Conversation document not found: ${conversationId}`);
      return null;
    }

    const convData = convDoc.data();
    const participants = convData.participants || {};
    
    // Get list of other participant IDs (excluding the sender)
    const otherUserIds = Object.keys(participants).filter(uid => uid !== senderId);
    if (otherUserIds.length === 0) {
      console.log("[FCM Trigger] No other participants to send notifications to.");
      return null;
    }

    const senderName = participants[senderId]?.name || "New Chat Message";

    // 2. Dispatch notifications to all other participants in parallel
    const promises = otherUserIds.map(async (recipientId) => {
      // Get all active FCM tokens registered for this user
      const tokensSnap = await admin.firestore()
        .collection("users")
        .doc(recipientId)
        .collection("fcm_tokens")
        .get();

      if (tokensSnap.empty) {
        console.log(`[FCM Trigger] Recipient ${recipientId} has no registered FCM tokens.`);
        return;
      }

      const tokens = tokensSnap.docs.map(doc => doc.data().token).filter(Boolean);
      if (tokens.length === 0) return;

      console.log(`[FCM Trigger] Sending push to ${tokens.length} tokens for recipient: ${recipientId}`);

      const payload = {
        notification: {
          title: senderName,
          body: content,
        },
        data: {
          conversationId: conversationId,
          senderId: senderId
        }
      };

      // 3. Send multicast message to all registered devices of the target recipient
      const response = await admin.messaging().sendEachForMulticast({
        tokens: tokens,
        notification: payload.notification,
        data: payload.data,
        webpush: {
          headers: {
            Urgency: "high"
          },
          notification: {
            title: payload.notification.title,
            body: payload.notification.body,
            icon: "/favicon.png",
            badge: "/favicon.png",
            // Include deep link click action (customized for web)
            click_action: `https://${process.env.GCLOUD_PROJECT || 'my-chat-aa484'}.web.app/#/chat?id=${conversationId}`
          }
        }
      });

      // 4. Cleanup expired, invalid, or stale registration tokens from Firestore
      const tokensToRemove = [];
      response.responses.forEach((resp, index) => {
        if (!resp.success) {
          const err = resp.error;
          console.error(`[FCM Trigger] Failed to send push to token index ${index}:`, err.message);
          
          if (err.code === "messaging/invalid-registration-token" ||
              err.code === "messaging/registration-token-not-registered") {
            // Delete token matching index from database
            const docToDelete = tokensSnap.docs[index].ref;
            tokensToRemove.push(docToDelete.delete());
          }
        }
      });
      
      if (tokensToRemove.length > 0) {
        await Promise.all(tokensToRemove);
        console.log(`[FCM Trigger] Cleaned up ${tokensToRemove.length} stale/expired FCM tokens.`);
      }
    });

    await Promise.all(promises);
    return null;
  });
