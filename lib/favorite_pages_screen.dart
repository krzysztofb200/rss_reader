import 'package:flutter/material.dart';
import 'package:rss_reader/website_articles_list.dart';
import 'package:sqflite/sqflite.dart';
import 'package:webfeed/webfeed.dart';
import 'package:http/http.dart' as http;

class FavoritePagesScreen extends StatefulWidget {
  final Future<Database> database;

  FavoritePagesScreen({required this.database});

  @override
  _FavoritePagesScreenState createState() => _FavoritePagesScreenState();
}

class _FavoritePagesScreenState extends State<FavoritePagesScreen> {
  List<Map<String, dynamic>> favoritePages = [];

  @override
  void initState() {
    super.initState();
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
      future: _buildFavoritePagesWidgets(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text('Brak ulubionych'),
          );
        } else {
          return ListView(
            children: snapshot.data!,
          );
        }
      },
    );
  }

  Future<List<Widget>> _buildFavoritePagesWidgets(BuildContext context) async {
    final List<Widget> widgets = [];
    for (int index = 0; index < favoritePages.length; index++) {
      final website = favoritePages[index]['page'];
      final link = favoritePages[index]['link'];
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
