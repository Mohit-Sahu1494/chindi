// Firebase Cloud Messaging Service Worker for Chindi Web
importScripts('https://www.gstatic.com/firebasejs/9.22.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.22.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyBpDJkdPS02OBziX_hIkvPN2DEE1PvR_Dk",
  appId: "1:1036203167129:web:c600b17575e077ec941708",
  messagingSenderId: "1036203167129",
  projectId: "chindi-90259",
  storageBucket: "chindi-90259.firebasestorage.app"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification?.title || 'Chindi';
  const notificationOptions = {
    body: payload.notification?.body || 'New message in Chindi',
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
