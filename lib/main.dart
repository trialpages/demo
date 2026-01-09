import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart'; // Tarih formatı için

void main() {
  runApp(const MyApp());
}

// --- Ana Uygulama Yapısı ---
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'İslam Ansiklopedisi',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
        fontFamily: 'Roboto', // Varsa özel font yoksa varsayılan
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
      ),
      home: const SplashScreen(), // İlk açılışta Splash ekranı
    );
  }
}

// --- 1. Bölüm: Açılış Ekranı (Splash Screen) ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 3 Saniye sonra ana sayfaya git
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const BrowserPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[800],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book_rounded, size: 100, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              "İSLAM ANSİKLOPEDİSİ",
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20)),
              child: const Text(
                "Doğru Bilginin Kaynağı",
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

// --- 2. Bölüm: Ana Tarayıcı Sayfası ---
class BrowserPage extends StatefulWidget {
  const BrowserPage({super.key});

  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage> {
  late final WebViewController controller;
  String currentUrl = 'https://islamansiklopedisi.org.tr';
  String currentTitle = 'Ana Sayfa';

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) async {
            // Sayfa yüklenince başlığı çekmeye çalış
            String? title = await controller.runJavaScriptReturningResult('document.title') as String;
            // Gelen başlık tırnak içinde gelir, onları temizle
            title = title.replaceAll('"', '');
            if(mounted) {
              setState(() {
                currentUrl = url;
                currentTitle = title.isEmpty ? 'Ansiklopedi' : title;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(currentUrl));
  }

  // Hamburger Menü İşlevleri
  void _goHome() {
    controller.loadRequest(Uri.parse('https://islamansiklopedisi.org.tr'));
    Navigator.pop(context); // Menüyü kapat
  }

  // Not Ekleme Penceresi
  void _addNote() async {
    final titleController = TextEditingController(text: currentTitle);
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(children: [Icon(Icons.edit_note), SizedBox(width: 10), Text("Not Ekle")]),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Başlık", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: "Notunuz", border: OutlineInputBorder(), hintText: "Buraya not alın..."),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () {
              DataManager.saveNote(titleController.text, noteController.text, currentUrl);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Not Kaydedildi")));
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  // Yer İmi Ekleme
  void _addBookmark() {
    DataManager.saveBookmark(currentTitle, currentUrl);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yer İmlerine Eklendi")));
  }

  // Geri Tuşu Kontrolü
  Future<bool> _onWillPop() async {
    if (await controller.canGoBack()) {
      controller.goBack();
      return false;
    }
    return true; // Çıkışa izin ver (Çift tık kontrolü eklenebilir ama menüde Çıkış var)
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("İslam Ansiklopedisi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(icon: const Icon(Icons.bookmark_add), onPressed: _addBookmark, tooltip: "Yer İmi Ekle"),
            IconButton(icon: const Icon(Icons.note_add), onPressed: _addNote, tooltip: "Not Al"),
          ],
        ),
        // --- Hamburger Menü (Drawer) ---
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(color: Colors.teal[700]),
                accountName: const Text("İslam Ansiklopedisi", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                accountEmail: const Text("Doğru Bilginin Kaynağı"),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.menu_book, size: 40, color: Colors.teal),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home, color: Colors.teal),
                title: const Text('Ana Sayfa'),
                onTap: _goHome,
              ),
              ListTile(
                leading: const Icon(Icons.bookmarks, color: Colors.teal),
                title: const Text('Yer İmleri'),
                onTap: () {
                  Navigator.pop(context); // Menüyü kapat
                  Navigator.push(context, MaterialPageRoute(builder: (context) => BookmarksPage(controller: controller)));
                },
              ),
              ListTile(
                leading: const Icon(Icons.description, color: Colors.teal),
                title: const Text('Notlarım'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => NotesPage(controller: controller)));
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.teal),
                title: const Text('Hakkında / Info'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const InfoPage()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.red),
                title: const Text('Çıkış'),
                onTap: () => SystemNavigator.pop(), // Uygulamayı kapatır (Android)
              ),
            ],
          ),
        ),
        body: WebViewWidget(controller: controller),
      ),
    );
  }
}

// --- 3. Bölüm: Yer İmleri Sayfası ---
class BookmarksPage extends StatefulWidget {
  final WebViewController controller;
  const BookmarksPage({super.key, required this.controller});

  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  List<Map<String, String>> bookmarks = [];

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  void _loadBookmarks() async {
    final list = await DataManager.getBookmarks();
    setState(() { bookmarks = list; });
  }

  void _deleteBookmark(int index) async {
    await DataManager.deleteBookmark(index);
    _loadBookmarks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yer İmleri")),
      body: bookmarks.isEmpty
          ? const Center(child: Text("Henüz yer imi eklemediniz.", style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              itemCount: bookmarks.length,
              itemBuilder: (context, index) {
                final item = bookmarks[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: const Icon(Icons.bookmark, color: Colors.orange),
                    title: Text(item['title'] ?? 'Başlıksız', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(item['url'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _deleteBookmark(index),
                    ),
                    onTap: () {
                      widget.controller.loadRequest(Uri.parse(item['url']!));
                      Navigator.pop(context); // Listeden çık ve tarayıcıya dön
                    },
                  ),
                );
              },
            ),
    );
  }
}

// --- 4. Bölüm: Notlar Sayfası ---
class NotesPage extends StatefulWidget {
  final WebViewController controller;
  const NotesPage({super.key, required this.controller});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<Map<String, String>> notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() async {
    final list = await DataManager.getNotes();
    setState(() { notes = list; });
  }

  void _deleteNote(int index) async {
    await DataManager.deleteNote(index);
    _loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: const Text("Notlarım")),
      body: notes.isEmpty
          ? const Center(child: Text("Henüz not almadınız.", style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.all(10),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(note['title'] ?? 'Başlıksız', 
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _deleteNote(index),
                            )
                          ],
                        ),
                        const Divider(),
                        Text(note['content'] ?? '', style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            icon: const Icon(Icons.link, size: 16),
                            label: const Text("Kaynağa Git"),
                            onPressed: () {
                              widget.controller.loadRequest(Uri.parse(note['url']!));
                              Navigator.pop(context);
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// --- 5. Bölüm: Info Sayfası ---
class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hakkında")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_user, size: 80, color: Colors.teal),
              const SizedBox(height: 20),
              const Text("İslam Ansiklopedisi", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const Text("v1.0.0", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              const Card(
                color: Colors.black87,
                child: Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Text(
                    "hmdysn tarafından geliştirilen uygulamalar",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Bu uygulama TDV İslam Ansiklopedisi web sitesine kolay erişim sağlamak amacıyla tasarlanmıştır.",
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 6. Bölüm: Veri Yöneticisi (Arka Plan İşleri) ---
class DataManager {
  static Future<void> saveBookmark(String title, String url) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedList = prefs.getStringList('bookmarks_v2') ?? [];
    
    Map<String, String> newItem = {'title': title, 'url': url};
    savedList.add(jsonEncode(newItem)); // JSON olarak kaydet
    
    await prefs.setStringList('bookmarks_v2', savedList);
  }

  static Future<List<Map<String, String>>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedList = prefs.getStringList('bookmarks_v2') ?? [];
    
    return savedList.map((item) {
      return Map<String, String>.from(jsonDecode(item));
    }).toList();
  }

  static Future<void> deleteBookmark(int index) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedList = prefs.getStringList('bookmarks_v2') ?? [];
    savedList.removeAt(index);
    await prefs.setStringList('bookmarks_v2', savedList);
  }

  static Future<void> saveNote(String title, String content, String url) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedList = prefs.getStringList('notes_v2') ?? [];
    
    Map<String, String> newNote = {
      'title': title,
      'content': content,
      'url': url,
      'date': DateFormat('dd.MM.yyyy').format(DateTime.now())
    };
    savedList.add(jsonEncode(newNote));
    
    await prefs.setStringList('notes_v2', savedList);
  }

  static Future<List<Map<String, String>>> getNotes() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedList = prefs.getStringList('notes_v2') ?? [];
    
    return savedList.map((item) {
      return Map<String, String>.from(jsonDecode(item));
    }).toList();
  }

  static Future<void> deleteNote(int index) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedList = prefs.getStringList('notes_v2') ?? [];
    savedList.removeAt(index);
    await prefs.setStringList('notes_v2', savedList);
  }
}