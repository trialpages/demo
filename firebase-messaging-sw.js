importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-messaging-compat.js');

// --- DİKKAT: BURAYA KENDİ PROJE BİLGİLERİNİ GİR ---
const firebaseConfig = {
  apiKey: "AIzaSyAr5FUC9uAmPkRWz1nqtllBodHYqpBB9ac",
  authDomain: "arabicinlevels.firebaseapp.com",
  projectId: "arabicinlevels",
  storageBucket: "arabicinlevels.firebasestorage.app",
  messagingSenderId: "240587696722",
  appId: "1:240587696722:web:6ad23e4fb519a1e5db8d8b",
  measurementId: "G-10RV9BVZWS"
};
// --------------------------------------------------

firebase.initializeApp(firebaseConfig);

const messaging = firebase.messaging();

/**
 * Arka plan mesajlarını yakalama fonksiyonu.
 * Çift bildirim sorununu çözen mantık buradadır.
 */
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Arka plan mesajı alındı:', payload);

  // --- ÇİFT BİLDİRİMİ ENGELLEYEN KOD BLOĞU ---
  // Eğer gelen pakette 'notification' nesnesi varsa, tarayıcı bunu 
  // otomatik olarak gösterecektir. Bizim tekrar göstermemize gerek yok.
  if (payload.notification) {
    console.log("Bu bir bildirim mesajı, tarayıcı otomatik gösterecek. Manuel işlem iptal edildi.");
    return; // Fonksiyondan çık, ikinciyi basma!
  }
  // -------------------------------------------

  // Eğer mesaj sadece 'data' içeriyorsa (Özel backend gönderimleri için)
  // o zaman manuel olarak göstermemiz gerekir:
  const notificationTitle = payload.data.title || "Yeni Mesaj";
  const notificationOptions = {
    body: payload.data.body || "İçerik bulunamadı.",
    icon: '/icon.png', // Varsa ikon yolunu buraya yaz
    // tag: 'haber-bildirimi' // İstersen aynı etiketli mesajların birbirini ezmesi için açabilirsin
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});