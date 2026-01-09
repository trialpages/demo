import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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
        primarySwatch: Colors.teal,
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
  String currentUrl = 'https://islamansiklopedisi.org.tr';
  String currentTitle = 'Ana Sayfa';

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) async {
          if(mounted) {
            String? title = await controller.runJavaScriptReturningResult('document.title') as String;
            setState(() { 
              currentUrl = url; 
              currentTitle = title.replaceAll('"', ''); 
            });
          }
        }
      ))
      ..loadRequest(Uri.parse(currentUrl));
  }

  void _addNote() {
    final tCtrl = TextEditingController(text: currentTitle);
    final nCtrl = TextEditingController();
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text("Not Ekle"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: tCtrl, decoration: const InputDecoration(labelText: "Başlık")),
        TextField(controller: nCtrl, maxLines: 3, decoration: const InputDecoration(labelText: "Not")),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text("İptal")),
        ElevatedButton(onPressed: () {
          DataManager.saveNote(tCtrl.text, nCtrl.text, currentUrl);
          Navigator.pop(c);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kaydedildi")));
        }, child: const Text("Kaydet"))
      ],
    ));
  }

  void _addBookmark() {
    DataManager.saveBookmark(currentTitle, currentUrl);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yer İmi Eklendi")));
  }

  Future<bool> _onWillPop() async {
    if (await controller.canGoBack()) { controller.goBack(); return false; }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(onWillPop: _onWillPop, child: Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        title: const Text("İslam Ansiklopedisi"), 
        actions: [
          IconButton(icon: const Icon(Icons.bookmark_add), onPressed: _addBookmark),
          IconButton(icon: const Icon(Icons.note_add), onPressed: _addNote),
      ]),
      drawer: Drawer(child: ListView(padding: EdgeInsets.zero, children: [
         const UserAccountsDrawerHeader(
           decoration: BoxDecoration(color: Colors.teal),
           accountName: Text("İslam Ansiklopedisi"),
           accountEmail: Text("Doğru Bilginin Kaynağı"),
           currentAccountPicture: CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.menu_book, color: Colors.teal)),
         ),
         ListTile(leading: const Icon(Icons.home), title: const Text('Ana Sayfa'), onTap: (){
           controller.loadRequest(Uri.parse('https://islamansiklopedisi.org.tr')); Navigator.pop(context);
         }),
         ListTile(leading: const Icon(Icons.bookmarks), title: const Text('Yer İmleri'), onTap: (){
           Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (c)=>BookmarksPage(controller: controller)));
         }),
         ListTile(leading: const Icon(Icons.description), title: const Text('Notlarım'), onTap: (){
           Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (c)=>NotesPage(controller: controller)));
         }),
      ])),
      body: WebViewWidget(controller: controller),
    ));
  }
}

// --- YARDIMCI SAYFALAR ---
class BookmarksPage extends StatefulWidget { final WebViewController controller; const BookmarksPage({super.key, required this.controller}); @override State<BookmarksPage> createState() => _S(); }
class _S extends State<BookmarksPage> {
  List<Map<String,String>> l=[]; @override void initState(){super.initState();_L();} void _L()async{final d=await DataManager.get('bm');setState((){l=d;});}
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Yer İmleri")), body: l.isEmpty ? const Center(child:Text("Boş")) : ListView.builder(itemCount: l.length, itemBuilder: (c,i)=>ListTile(
    title: Text(l[i]['t']!), subtitle: Text(l[i]['u']!), onTap: (){widget.controller.loadRequest(Uri.parse(l[i]['u']!));Navigator.pop(c);},
    trailing: IconButton(icon: const Icon(Icons.delete,color:Colors.red),onPressed: ()async{await DataManager.del('bm',i);_L();}),
  )));
}

class NotesPage extends StatefulWidget { final WebViewController controller; const NotesPage({super.key, required this.controller}); @override State<NotesPage> createState() => _N(); }
class _N extends State<NotesPage> {
  List<Map<String,String>> l=[]; @override void initState(){super.initState();_L();} void _L()async{final d=await DataManager.get('nt');setState((){l=d;});}
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Notlarım")), body: l.isEmpty ? const Center(child:Text("Boş")) : ListView.builder(itemCount: l.length, itemBuilder: (c,i)=>Card(margin:const EdgeInsets.all(5),child:ListTile(
    title: Text(l[i]['t']!), subtitle: Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(l[i]['c']!),Text(l[i]['d']!,style:const TextStyle(fontSize:10,color:Colors.grey))]),
    onTap: (){widget.controller.loadRequest(Uri.parse(l[i]['u']!));Navigator.pop(c);},
    trailing: IconButton(icon: const Icon(Icons.delete,color:Colors.red),onPressed: ()async{await DataManager.del('nt',i);_L();}),
  ))));
}

class DataManager {
  static Future<void> saveBookmark(String t, String u) async => await add('bm', {'t':t,'u':u});
  // Tarihi artık manuel alıyoruz, paket kullanmıyoruz:
  static Future<void> saveNote(String t, String c, String u) async => await add('nt', {'t':t,'c':c,'u':u,'d':DateTime.now().toString().substring(0,16)});
  static Future<void> add(String k, Map<String,String> v) async { final p=await SharedPreferences.getInstance(); List<String> l=p.getStringList(k)??[]; l.add(jsonEncode(v)); await p.setStringList(k,l); }
  static Future<List<Map<String,String>>> get(String k) async { final p=await SharedPreferences.getInstance(); return (p.getStringList(k)??[]).map((e)=>Map<String,String>.from(jsonDecode(e))).toList(); }
  static Future<void> del(String k, int i) async { final p=await SharedPreferences.getInstance(); List<String> l=p.getStringList(k)??[]; if(i<l.length){l.removeAt(i);await p.setStringList(k,l);} }
}