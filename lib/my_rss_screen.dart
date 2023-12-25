import 'package:flutter/material.dart';
import 'package:rss_reader/website_articles_list.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;
import 'package:webfeed/webfeed.dart';

class MyRssScreen extends StatefulWidget {
  final Future<Database> database;

  MyRssScreen({required this.database});

  @override
  _MyRssScreenState createState() => _MyRssScreenState();
}

class _MyRssScreenState extends State<MyRssScreen> {
  List<Map<String, dynamic>> myRssFeeds = [];
  TextEditingController _nameController = TextEditingController();
  TextEditingController _linkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMyRssFeeds();
  }

  void _loadMyRssFeeds() async {
    final Database db = await widget.database;
    final List<Map<String, dynamic>> rssFeeds = await db.query('myRssFeeds');
    setState(() {
      myRssFeeds = rssFeeds;
    });
  }

  Future<void> _addRssFeed() async {
    final String name = _nameController.text.trim();
    final String link = _linkController.text.trim();

    if (name.isNotEmpty && link.isNotEmpty) {
      // Sprawdzenie, czy link jest poprawnym kanałem RSS
      bool isValidRss = await _isValidRssLink(link);

      if (isValidRss) {
        final Database db = await widget.database;
        await db.insert(
          'myRssFeeds',
          {'name': name, 'link': link},
        );

        _nameController.clear();
        _linkController.clear();
        _loadMyRssFeeds();
      } else {
        _showInvalidRssLinkDialog();
      }
    }
  }

  Future<bool> _isValidRssLink(String link) async {
    try {
      final response = await http.get(Uri.parse(link));
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print('Error validating RSS link: $e');
    }
    return false;
  }

  void _showInvalidRssLinkDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Nieprawidłowy link RSS'),
          content: Text('Podany link nie jest prawidłowym kanałem RSS.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteRssFeed(int id) async {
    final Database db = await widget.database;
    await db.delete(
      'myRssFeeds',
      where: 'id = ?',
      whereArgs: [id],
    );

    _loadMyRssFeeds();
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
    return Scaffold(
      body: _buildRssFeedList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRssFeedDialog(),
        tooltip: 'Dodaj RSS',
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildRssFeedList() {
    return ListView.builder(
      itemCount: myRssFeeds.length,
      itemBuilder: (context, index) {
        final rssFeed = myRssFeeds[index];
        final name = rssFeed['name'];
        final link = rssFeed['link'];

        return Card(
          elevation: 2,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            title: Text(
              name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: FutureBuilder<String?>(
              future: _fetchLogo(context, link),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox.shrink(); // Placeholder or loading indicator can be added here
                } else if (snapshot.hasError) {
                  return SizedBox.shrink(); // Placeholder for error state
                } else {
                  final logoUrl = snapshot.data;
                  return logoUrl != null
                      ? Image.network(
                          logoUrl,
                          width: 80,
                          height: 40,
                          fit: BoxFit.contain,
                        )
                      : SizedBox.shrink();
                }
              },
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                _deleteRssFeed(rssFeed['id']);
              },
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WebsiteArticlesList(website: name, link: link),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showAddRssFeedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Dodaj nowy kanał RSS'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nazwa RSS'),
              ),
              TextField(
                controller: _linkController,
                decoration: InputDecoration(labelText: 'Link'),
              ),
              ElevatedButton(
                onPressed: () {
                  _addRssFeed();
                  Navigator.of(context).pop();
                },
                child: Text('Dodaj'),
              ),
            ],
          ),
        );
      },
    );
  }
}
