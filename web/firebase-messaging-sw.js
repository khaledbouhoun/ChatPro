importScripts("https://www.gstatic.com/firebasejs/10.11.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.11.0/firebase-messaging-compat.js");

// Initialize Firebase App in service worker
// Using the same credentials from your main app config
firebase.initializeApp({
  apiKey: "AIzaSyD8pHyc7sPYyvoj_bfK64VKKIEGDC1MTzU",
  authDomain: "my-chat-aa484.firebaseapp.com",
  projectId: "my-chat-aa484",
  storageBucket: "my-chat-aa484.firebasestorage.app",
  messagingSenderId: "779286426832",
  appId: "1:779286426832:web:d6627db7ba518cda499ad5"
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log("[SW] Background message received:", payload);
  
  const notificationTitle = payload.notification?.title || "New Message";
  const notificationOptions = {
    body: payload.notification?.body || "",
    icon: "/favicon.png",
    badge: "/favicon.png",
    data: {
      conversationId: payload.data?.conversationId,
      senderId: payload.data?.senderId
    }
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Intercept notification clicks
self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  const conversationId = event.notification.data?.conversationId;
  
  if (!conversationId) return;

  const appUrl = new URL('/#/chat?id=' + conversationId, self.location.origin).href;
  
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(windowClients) {
      // Check if a tab is already open
      for (var i = 0; i < windowClients.length; i++) {
        var client = windowClients[i];
        if (client.url === appUrl || 'focus' in client) {
          // Post message to the app so GetX handles navigation internally
          client.postMessage({
            type: 'NAVIGATE_TO_CONVERSATION',
            conversationId: conversationId
          });
          return client.focus();
        }
      }
      
      // If no tab is open, open a new one
      if (clients.openWindow) {
        return clients.openWindow(appUrl);
      }
    })
  );
});
