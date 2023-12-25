import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rss_reader/all_pages_screen.dart';
import 'package:rss_reader/favorite_pages_screen.dart';
import 'package:rss_reader/website_articles_list.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:webfeed/webfeed.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = openDatabase(
    join(await getDatabasesPath(), 'favorites_database.db'),
    onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE favorites(id INTEGER PRIMARY KEY, page TEXT, link TEXT)',
      );
    },
    version: 1,
  );

  runApp(MyApp(database: database));
}

class MyApp extends StatelessWidget {
  final Future<Database> database;

  MyApp({required this.database});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Bottom Nav',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(database: database),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final Future<Database> database;

  MyHomePage({required this.database});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Wszystkie Strony' : 'Ulubione'),
      ),
      body: _selectedIndex == 0
          ? AllPagesScreen(
              database: widget.database,
            )
          : FavoritePagesScreen(
              database: widget.database,
            ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Wszystkie Strony',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'Ulubione',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}
