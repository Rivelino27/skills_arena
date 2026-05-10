// Skills Arena — Cloud Functions
//
// Single function: `onChatMessage` listens for new docs in
// `chats/{chatId}/messages/{msgId}` and pushes an FCM notification to
// every chat participant except the sender.
//
// Deploy:
//   cd functions && npm install && npm run deploy
//
// Requires: Firebase Blaze plan (Spark does not run Cloud Functions
// with outbound network/FCM).

import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";

admin.initializeApp();

interface ChatDoc {
  participants: string[];
  groupName?: string;
  participantNames?: Record<string, string>;
  isGroup?: boolean;
}

interface MessageDoc {
  senderId: string;
  senderName?: string;
  text: string;
  type?: string;
}

export const onChatMessage = functions.firestore
  .document("chats/{chatId}/messages/{msgId}")
  .onCreate(async (snap, ctx) => {
    const msg = snap.data() as MessageDoc;
    const chatId = ctx.params.chatId as string;

    const chatSnap = await admin
      .firestore()
      .collection("chats")
      .doc(chatId)
      .get();
    const chat = chatSnap.data() as ChatDoc | undefined;
    if (!chat) {
      console.log("chat doc missing", chatId);
      return;
    }

    const recipients = (chat.participants || []).filter(
      (uid) => uid !== msg.senderId
    );
    if (recipients.length === 0) return;

    // Resolve display title: 1-1 = sender name, group = group name + sender.
    const senderName =
      msg.senderName ||
      chat.participantNames?.[msg.senderId] ||
      "Alguém";
    const isGroup = chat.isGroup === true;
    const title = isGroup
      ? chat.groupName || "Grupo"
      : senderName;
    const body = isGroup
      ? `${senderName}: ${msg.text}`
      : msg.text;

    // Pull tokens from each recipient's user doc. Tokens are stored as
    // an array under `users/{uid}.fcmTokens` by NotificationService.
    const usersSnap = await admin
      .firestore()
      .getAll(
        ...recipients.map((uid) =>
          admin.firestore().collection("users").doc(uid)
        )
      );

    const tokens: string[] = [];
    const tokenOwner = new Map<string, string>();
    for (const userSnap of usersSnap) {
      const data = userSnap.data() as
        | { fcmTokens?: string[] }
        | undefined;
      if (!data?.fcmTokens) continue;
      for (const t of data.fcmTokens) {
        tokens.push(t);
        tokenOwner.set(t, userSnap.id);
      }
    }
    if (tokens.length === 0) return;

    const messaging = admin.messaging();
    // Send one-by-one so we can prune dead tokens individually.
    const dead: { ownerUid: string; token: string }[] = [];
    await Promise.all(
      tokens.map(async (token) => {
        try {
          await messaging.send({
            token,
            notification: { title, body },
            android: {
              priority: "high",
              notification: {
                channelId: "messages",
                clickAction: "FLUTTER_NOTIFICATION_CLICK",
              },
            },
            apns: {
              payload: { aps: { sound: "default" } },
            },
            data: {
              chatId,
              type: "chat_message",
            },
          });
        } catch (err) {
          const msg = (err as { code?: string }).code || "";
          if (
            msg.includes("registration-token-not-registered") ||
            msg.includes("invalid-argument")
          ) {
            const owner = tokenOwner.get(token);
            if (owner) dead.push({ ownerUid: owner, token });
          } else {
            console.warn("FCM send failed", err);
          }
        }
      })
    );

    // Clean up dead tokens.
    if (dead.length > 0) {
      const byOwner = new Map<string, string[]>();
      for (const d of dead) {
        const list = byOwner.get(d.ownerUid) || [];
        list.push(d.token);
        byOwner.set(d.ownerUid, list);
      }
      await Promise.all(
        Array.from(byOwner.entries()).map(([uid, deadTokens]) =>
          admin
            .firestore()
            .collection("users")
            .doc(uid)
            .update({
              fcmTokens: admin.firestore.FieldValue.arrayRemove(
                ...deadTokens
              ),
            })
        )
      );
    }
  });
