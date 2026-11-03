const path = require('path');
const fs = require('fs');
const User = require('../models/User');
const Group = require('../models/Group');

let admin = null;
let isFirebaseInitialized = false;

try {
  admin = require('firebase-admin');
} catch (_) {}

function initFirebase() {
  if (isFirebaseInitialized || !admin) return;

  try {
    const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT;
    if (serviceAccountJson) {
      let credentials;
      if (serviceAccountJson.trim().startsWith('{')) {
        credentials = JSON.parse(serviceAccountJson);
      } else {
        const filePath = path.isAbsolute(serviceAccountJson)
          ? serviceAccountJson
          : path.resolve(process.cwd(), serviceAccountJson);
        credentials = JSON.parse(fs.readFileSync(filePath, 'utf8'));
      }
      admin.initializeApp({
        credential: admin.credential.cert(credentials),
      });
      isFirebaseInitialized = true;
      console.log('[FCM] Firebase Admin SDK initialized successfully');
    } else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      admin.initializeApp();
      isFirebaseInitialized = true;
      console.log('[FCM] Firebase initialized via GOOGLE_APPLICATION_CREDENTIALS');
    } else {
      console.log('[FCM] FIREBASE_SERVICE_ACCOUNT not set in .env. Push notifications active in local & WebSocket mode.');
    }
  } catch (err) {
    console.warn('[FCM] Firebase initialization notice:', err.message);
  }
}

// Auto-initialize on module load
initFirebase();

/**
 * Registers an FCM device token for a user.
 */
async function registerFCMToken(userId, fcmToken) {
  if (!fcmToken || typeof fcmToken !== 'string') return;
  try {
    await User.findByIdAndUpdate(userId, {
      $addToSet: { fcmTokens: fcmToken.trim() },
    });
  } catch (e) {
    console.error('[FCM] Error registering token:', e.message);
  }
}

/**
 * Removes an FCM device token (e.g. on logout).
 */
async function removeFCMToken(userId, fcmToken) {
  if (!fcmToken) return;
  try {
    await User.findByIdAndUpdate(userId, {
      $pull: { fcmTokens: fcmToken },
    });
  } catch (e) {
    console.error('[FCM] Error removing token:', e.message);
  }
}

/**
 * Sends a push notification to all members of a group except the sender.
 */
async function sendGroupPushNotification({ groupId, title, body, data = {}, excludeUserId = null }) {
  try {
    const group = await Group.findById(groupId);
    if (!group) return;

    // Filter recipients
    const recipientIds = group.members.filter(
      memberId => !excludeUserId || memberId.toString() !== excludeUserId.toString()
    );

    if (recipientIds.length === 0) return;

    // Fetch users with their FCM tokens
    const users = await User.find({ _id: { $in: recipientIds } }).select('fcmTokens name');
    const tokens = [];
    users.forEach(u => {
      if (Array.isArray(u.fcmTokens)) {
        tokens.push(...u.fcmTokens);
      }
    });

    if (tokens.length === 0) return;

    if (isFirebaseInitialized && admin) {
      const message = {
        notification: {
          title: title || group.name,
          body: body,
        },
        data: {
          groupId: groupId.toString(),
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
          ...data,
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'chindi_alerts',
            priority: 'max',
            defaultSound: true,
            defaultVibrateTimings: true,
            icon: 'ic_launcher',
          },
        },
        apns: {
          headers: {
            'apns-priority': '10',
          },
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
              contentAvailable: true,
            },
          },
        },
        tokens: tokens,
      };

      const response = await admin.messaging().sendEachForMulticast(message);
      console.log(`[FCM] Sent notification to ${response.successCount} devices (${response.failureCount} failed)`);

      // Clean up stale tokens if any failed
      if (response.failureCount > 0) {
        response.responses.forEach((resp, idx) => {
          if (!resp.success && resp.error) {
            const code = resp.error.code;
            if (
              code === 'messaging/invalid-registration-token' ||
              code === 'messaging/registration-token-not-registered'
            ) {
              const staleToken = tokens[idx];
              User.updateMany({ fcmTokens: staleToken }, { $pull: { fcmTokens: staleToken } }).exec();
            }
          }
        });
      }
    } else {
      console.log(`[FCM Notification Simulated] Title: "${title}" | Body: "${body}" | Recipients: ${recipientIds.length}`);
    }
  } catch (error) {
    console.error('[FCM] Error sending group push notification:', error.message);
  }
}

/**
 * Sends a push notification to a specific single user (e.g. when added to a group).
 */
async function sendUserPushNotification({ userId, title, body, data = {} }) {
  try {
    const user = await User.findById(userId).select('fcmTokens name');
    if (!user || !Array.isArray(user.fcmTokens) || user.fcmTokens.length === 0) return;

    const tokens = user.fcmTokens.filter(t => typeof t === 'string' && t.trim().length > 0);
    if (tokens.length === 0) return;

    if (isFirebaseInitialized && admin) {
      const message = {
        notification: {
          title: title || 'Chindi Alert',
          body: body,
        },
        data: {
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
          ...data,
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'chindi_alerts',
            priority: 'max',
            defaultSound: true,
            defaultVibrateTimings: true,
            icon: 'ic_launcher',
          },
        },
        apns: {
          headers: {
            'apns-priority': '10',
          },
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
              contentAvailable: true,
            },
          },
        },
        tokens: tokens,
      };

      const response = await admin.messaging().sendEachForMulticast(message);
      console.log(`[FCM] Sent user notification to ${response.successCount} devices (${response.failureCount} failed)`);

      if (response.failureCount > 0) {
        response.responses.forEach((resp, idx) => {
          if (!resp.success && resp.error) {
            const code = resp.error.code;
            if (
              code === 'messaging/invalid-registration-token' ||
              code === 'messaging/registration-token-not-registered'
            ) {
              const staleToken = tokens[idx];
              User.updateMany({ fcmTokens: staleToken }, { $pull: { fcmTokens: staleToken } }).exec();
            }
          }
        });
      }
    } else {
      console.log(`[FCM Notification Simulated] To User: ${user.name} | Title: "${title}" | Body: "${body}"`);
    }
  } catch (error) {
    console.error('[FCM] Error sending user push notification:', error.message);
  }
}

module.exports = {
  initFirebase,
  registerFCMToken,
  removeFCMToken,
  sendGroupPushNotification,
  sendUserPushNotification,
};
