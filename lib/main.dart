import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';

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
        primarySwatch: Colors.teal,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// --- AÇILIŞ EKRANI ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const BrowserPage()),
        );
      }
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
            const Icon(Icons.menu_book, size: 100, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              "İSLAM ANSİKLOPEDİSİ",
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text(
              "Doğru Bilginin Kaynağı",
              style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

// --- ANA TARAYICI SAYFASI ---
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
            String? title = await controller.runJavaScriptReturningResult('document.title') as String;
            title = title.replaceAll('"', '');
            if (mounted) {
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

  void _addNote() {
    final titleController = TextEditingController(text: currentTitle);
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Not Ekle"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Başlık")),
            const SizedBox(height: 10),
            TextField(controller: noteController, maxLines: 3, decoration: const InputDecoration(labelText: "Not")),
          ],
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

  void _addBookmark() {
    DataManager.saveBookmark(currentTitle, currentUrl);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yer İmlerine Eklendi")));
  }

  // Yeni sürüm Flutter için Geri Tuşu Yönetimi
  Future<bool> _onWillPop() async {
    if (await controller.canGoBack()) {
      controller.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("İslam Ansiklopedisi"),
          actions: [
            IconButton(icon: const Icon(Icons.bookmark_add), onPressed: _addBookmark),
            IconButton(icon: const Icon(Icons.note_add), onPressed: _addNote),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(color: Colors.teal[700]),
                accountName: const Text("İslam Ansiklopedisi"),
                accountEmail: const Text("Doğru Bilginin Kaynağı"),
                currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.menu_book, color: Colors.teal)),
              ),
              ListTile(leading: const Icon(Icons.home), title: const Text('Ana Sayfa'), onTap: () {
                controller.loadRequest(Uri.parse('https://islamansiklopedisi.org.tr'));
                Navigator.pop(context);
              }),
              ListTile(leading: const Icon(Icons.bookmarks), title: const Text('Yer İmleri'), onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => BookmarksPage(controller: controller)));
              }),
              ListTile(leading: const Icon(Icons.description), title: const Text('Notlarım'), onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => NotesPage(controller: controller)));
              }),
              const Divider(),
              ListTile(leading: const Icon(Icons.info), title: const Text('Hakkında'), onTap: () {
                 Navigator.pop(context);
                 Navigator.push(context, MaterialPageRoute(builder: (context) => const InfoPage()));
              }),
            ],
          ),
        ),
        body: WebViewWidget(controller: controller),
      ),
    );
  }
}

// --- YARDIMCI SAYFALAR VE VERİ YÖNETİMİ ---
class BookmarksPage extends StatefulWidget {
  final WebViewController controller;
  const BookmarksPage({super.key, required this.controller});
  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  List<Map<String, String>> bookmarks = [];
  @override void initState() { super.initState(); _load(); }
  void _load() async { final l = await DataManager.getBookmarks(); setState(() { bookmarks = l; }); }
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yer İmleri")),
      body: ListView.builder(itemCount: bookmarks.length, itemBuilder: (c, i) => ListTile(
        title: Text(bookmarks[i]['title']!), subtitle: Text(bookmarks[i]['url']!),
        onTap: () { widget.controller.loadRequest(Uri.parse(bookmarks[i]['url']!)); Navigator.pop(c); },
        trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async {
          await DataManager.deleteBookmark(i); _load();
        }),
      )),
    );
  }
}

class NotesPage extends StatefulWidget {
  final WebViewController controller;
  const NotesPage({super.key, required this.controller});
  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<Map<String, String>> notes = [];
  @override void initState() { super.initState(); _load(); }
  void _load() async { final l = await DataManager.getNotes(); setState(() { notes = l; }); }
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notlarım")),
      body: ListView.builder(itemCount: notes.length, itemBuilder: (c, i) => Card(margin: const EdgeInsets.all(8), child: ListTile(
        title: Text(notes[i]['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 5), Text(notes[i]['content']!), const SizedBox(height: 5),
          Text(notes[i]['date']!, style: const TextStyle(fontSize: 12, color: Colors.grey))
        ]),
        trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async {
          await DataManager.deleteNote(i); _load();
        }),
        onTap: () { widget.controller.loadRequest(Uri.parse(notes[i]['url']!)); Navigator.pop(c); },
      ))),
    );
  }
}

class InfoPage extends StatelessWidget {
  const InfoPage({super.key});
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hakkında")),
      body: const Center(child: Text("hmdysn tarafından geliştirilen uygulamalar", style: TextStyle(fontWeight: FontWeight.bold))),
    );
  }
}

class DataManager {
  static Future<void> saveBookmark(String t, String u) async {
    final p = await SharedPreferences.getInstance();
    List<String> l = p.getStringList('bm') ?? [];
    l.add(jsonEncode({'title': t, 'url': u}));
    await p.setStringList('bm', l);
  }
  static Future<List<Map<String, String>>> getBookmarks() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList('bm') ?? []).map((e) => Map<String, String>.from(jsonDecode(e))).toList();
  }
  static Future<void> deleteBookmark(int i) async {
    final p = await SharedPreferences.getInstance();
    List<String> l = p.getStringList('bm') ?? [];
    if(i < l.length) { l.removeAt(i); await p.setStringList('bm', l); }
  }
  static Future<void> saveNote(String t, String c, String u) async {
    final p = await SharedPreferences.getInstance();
    List<String> l = p.getStringList('nt') ?? [];
    l.add(jsonEncode({'title': t, 'content': c, 'url': u, 'date': DateFormat('dd.MM.yyyy').format(DateTime.now())}));
    await p.setStringList('nt', l);
  }
  static Future<List<Map<String, String>>> getNotes() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList('nt') ?? []).map((e) => Map<String, String>.from(jsonDecode(e))).toList();
  }
  static Future<void> deleteNote(int i) async {
    final p = await SharedPreferences.getInstance();
    List<String> l = p.getStringList('nt') ?? [];
    if(i < l.length) { l.removeAt(i); await p.setStringList('nt', l); }
  }
}