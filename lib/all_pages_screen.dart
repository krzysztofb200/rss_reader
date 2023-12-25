import 'package:flutter/material.dart';
import 'package:rss_reader/website_articles_list.dart';
import 'package:sqflite/sqflite.dart';
import 'package:webfeed/webfeed.dart';
import 'package:http/http.dart' as http;

class AllPagesScreen extends StatefulWidget {
  final Future<Database> database;

  AllPagesScreen({required this.database});

  @override
  _AllPagesScreenState createState() => _AllPagesScreenState();
}

class _AllPagesScreenState extends State<AllPagesScreen> {
  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Map<String, String> allPages = {
    'naekranie.pl': 'https://naekranie.pl/feed/news.xml',
    'BBC World': 'http://feeds.bbci.co.uk/news/world/rss.xml',
    'BBC UK': 'http://feeds.bbci.co.uk/news/uk/rss.xml',
    'The New York Times': 'https://rss.nytimes.com/services/xml/rss/nyt/World.xml',
    'The Washington Post': 'https://www.washingtonpost.com/arcio/rss/category/politics/?itid=lk_inline_manual_2',
    'Polsat News - Polska': 'https://www.polsatnews.pl/rss/polska.xml',
  };

  List<Map<String, dynamic>> favoritePages = [];

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

  Future<String?> _fetchLogo(BuildContext context, String rssLink) async {
    try {
      final response = await http.get(Uri.parse(rssLink));
      if (response.statusCode == 200) {
        final feed = RssFeed.parse(response.body);
        return feed.image?.url;
      }
    } catch (e) {
      print('Error fetching logo: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Widget>>(
      future: _buildAllPagesWidgets(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text('Brak stron'),
          );
        } else {
          return ListView(
            children: snapshot.data!,
          );
        }
      },
    );
  }

  Future<List<Widget>> _buildAllPagesWidgets(BuildContext context) async {
    final List<Widget> widgets = [];
    for (int index = 0; index < allPages.length; index++) {
      final website = allPages.keys.elementAt(index);
      final link = allPages[website]!;
      final isFavorite = favoritePages.any((fav) => fav['page'] == website);
      final logoUrl = await _fetchLogo(context, link);

      widgets.add(
        Card(
          elevation: 2,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            title: Text(
              website,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: logoUrl != null
                ? Image.network(
                    logoUrl,
                    width: 80,
                    height: 40,
                    fit: BoxFit.contain,
                  )
                : SizedBox.shrink(),
            trailing: IconButton(
              icon: isFavorite ? Icon(Icons.star, color: Colors.amber) : Icon(Icons.star_border),
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
        ),
      );
    }
    return widgets;
  }
}
