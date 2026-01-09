import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'İslam Ansiklopedisi',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const BrowserPage(),
    );
  }
}

class BrowserPage extends StatefulWidget {
  const BrowserPage({super.key});

  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage> {
  late final WebViewController controller;
  DateTime? lastPressed; // Çift geri basmayı kontrol etmek için
  String currentUrl = 'https://islamansiklopedisi.org.tr';
  final TextEditingController noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // WebView Ayarları
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              currentUrl = url;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(currentUrl));
      
    _loadLastBookmark(); // Son kalınan yeri yükle
  }

  // --- Fonksiyonlar ---

  // Not Ekleme Penceresi
  void _showNoteDialog() async {
    final prefs = await SharedPreferences.getInstance();
    // O anki sayfa için kaydedilmiş notu getir
    String existingNote = prefs.getString('note_$currentUrl') ?? '';
    noteController.text = existingNote;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Notlar"),
        content: TextField(
          controller: noteController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: "Bu maddeyle ilgili notlarınız...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () {
              // Notu o anki URL anahtarıyla kaydet
              prefs.setString('note_$currentUrl', noteController.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Not kaydedildi!")),
              );
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  // Yer İmi Kaydetme
  void _saveBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_saved_url', currentUrl);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Yer imi eklendi: $currentUrl")),
      );
    }
  }

  // Son Kaldığım Yerden Devam Et
  void _loadLastBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedUrl = prefs.getString('last_saved_url');
    if (savedUrl != null) {
      controller.loadRequest(Uri.parse(savedUrl));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kaldığınız yere gidildi.")),
        );
      }
    }
  }

  // Geri Tuşu Kontrolü (Çift Tıklama ile Çıkış)
  Future<bool> _onWillPop() async {
    if (await controller.canGoBack()) {
      controller.goBack();
      return false; // Uygulamadan çıkma, tarayıcıda geri git
    } else {
      // Tarayıcı geçmişi bittiyse çift tık kontrolü yap
      final now = DateTime.now();
      final maxDuration = const Duration(seconds: 2);
      final isWarning = lastPressed == null || now.difference(lastPressed!) > maxDuration;

      if (isWarning) {
        lastPressed = DateTime.now();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Çıkmak için tekrar basın")),
        );
        return false;
      }
      return true; // Çıkış yap
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        // Üst Bar (Opsiyonel, yer kazanmak için kaldırılabilir ama menü için iyi)
        appBar: AppBar(
          title: const Text("TDV İslam Ansiklopedisi", style: TextStyle(fontSize: 16)),
          backgroundColor: Colors.white,
          elevation: 1,
          actions: [
            IconButton(
              icon: const Icon(Icons.bookmark_add),
              onPressed: _saveBookmark,
              tooltip: "Kaldığım Yeri Kaydet",
            ),
             IconButton(
              icon: const Icon(Icons.bookmark_border),
              onPressed: _loadLastBookmark,
              tooltip: "Kaldığım Yere Git",
            ),
          ],
        ),
        body: WebViewWidget(controller: controller),
        // Not Alma Butonu (Sağ Alt Köşe)
        floatingActionButton: FloatingActionButton(
          onPressed: _showNoteDialog,
          backgroundColor: Colors.green[700],
          child: const Icon(Icons.edit_note, color: Colors.white),
        ),
      ),
    );
  }
}