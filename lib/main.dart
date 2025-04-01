import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(DiaryApp());
}

class DiaryApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diary App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: DiaryScreen(),
    );
  }
}

class DiaryScreen extends StatefulWidget {
  @override
  _DiaryScreenState createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  late Database _database;
  List<Map<String, dynamic>> entries = [];
  TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'diary.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE entries(id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT, text TEXT)",
        );
      },
      version: 1,
    );
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final List<Map<String, dynamic>> data = await _database.query('entries');
    setState(() {
      entries = data;
    });
  }

  Future<void> _addEntry() async {
    if (_controller.text.isNotEmpty) {
      final String date = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
      await _database.insert(
        'entries',
        {'date': date, 'text': _controller.text},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _controller.clear();
      _loadEntries();
    }
  }

  Future<void> _deleteEntry(int id) async {
    await _database.delete(
      'entries',
      where: 'id = ?',
      whereArgs: [id],
    );
    _loadEntries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Diary Test')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: '今日をまとめよう',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _addEntry,
            child: Text('日記を追加'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(entries[index]['text']),
                    subtitle: Text(entries[index]['date']),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _deleteEntry(entries[index]['id']),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
