importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-messaging-compat.js');

// Senin Config Bilgilerin (Service Worker için)
const firebaseConfig = {
  apiKey: "AIzaSyAr5FUC9uAmPkRWz1nqtllBodHYqpBB9ac",
  authDomain: "arabicinlevels.firebaseapp.com",
  projectId: "arabicinlevels",
  storageBucket: "arabicinlevels.firebasestorage.app",
  messagingSenderId: "240587696722",
  appId: "1:240587696722:web:6ad23e4fb519a1e5db8d8b",
  measurementId: "G-10RV9BVZWS"
};

firebase.initializeApp(firebaseConfig);

const messaging = firebase.messaging();

// Arka plan mesajlarını yakalama
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Arka plan mesajı:', payload);
  
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: payload.notification.icon || '/icon.png' // Varsa ikon, yoksa boş
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});