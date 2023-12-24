import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rss_reader/website_articles_list.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'settings.dart';

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
  Map<String, String> allPages = {
    'naekranie.pl': 'https://naekranie.pl/feed/news.xml',
    'BBC World': 'http://feeds.bbci.co.uk/news/world/rss.xml',
    'BBC UK': 'http://feeds.bbci.co.uk/news/uk/rss.xml',
    'The New York Times': 'https://rss.nytimes.com/services/xml/rss/nyt/World.xml',
    'The Washington Post': 'https://www.washingtonpost.com/arcio/rss/category/politics/?itid=lk_inline_manual_2',
    'Polsat News - Polska': 'https://www.polsatnews.pl/rss/polska.xml',
  };

  List<Map<String, dynamic>> favoritePages = [];

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _toggleFavorite(String page, String link) async {
    final Database db = await widget.database;

    final List<Map<String, dynamic>> existingFavorites = await db.query(
      'favorites',
      where: 'page = ?',
      whereArgs: [page],
    );

    if (existingFavorites.isEmpty) {
      await db.insert(
        'favorites',
        {'page': page, 'link': link},
      );
    } else {
      await db.delete(
        'favorites',
        where: 'page = ?',
        whereArgs: [page],
      );
    }

    _loadFavorites();
  }

  void _loadFavorites() async {
    final Database db = await widget.database;
    final List<Map<String, dynamic>> favorites = await db.query('favorites');
    setState(() {
      favoritePages = favorites;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Wszystkie Strony' : 'Ulubione'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: _selectedIndex == 0 ? _buildAllPagesList() : _buildFavoritePagesList(),
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

  Widget _buildAllPagesList() {
    return ListView.builder(
      itemCount: allPages.length,
      itemBuilder: (context, index) {
        final website = allPages.keys.elementAt(index);
        final link = allPages[website]!;
        final isFavorite = favoritePages.any((fav) => fav['page'] == website);

        return Column(
          children: [
            ListTile(
              title: Text(website),
              trailing: IconButton(
                icon: isFavorite ? Icon(Icons.star) : Icon(Icons.star_border),
                color: isFavorite ? Colors.amber : null,
                onPressed: () {
                  _toggleFavorite(website, link);
                },
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WebsiteArticlesList(website: website, link: link),
                  ),
                );
              },
            ),
            Divider(
              height: 2,
              color: Colors.grey,
            )
          ],
        );
      },
    );
  }

  Widget _buildFavoritePagesList() {
    return ListView.builder(
      itemCount: favoritePages.length,
      itemBuilder: (context, index) {
        final website = favoritePages[index]['page'];
        final link = favoritePages[index]['link'];

        return Column(
          children: [
            ListTile(
              title: Text(website),
              onTap: () {
                // Otwarcie nowego ekranu z przekazaniem linka
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WebsiteArticlesList(website: website, link: link),
                  ),
                );
              },
            ),
            Divider(
              height: 2,
              color: Colors.grey,
            )
          ],
        );
      },
    );
  }
}
