import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webfeed/webfeed.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebsiteArticlesList extends StatefulWidget {
  final String link;
  final String website;

  @override
  _WebsiteArticlesListState createState() => _WebsiteArticlesListState();
  WebsiteArticlesList({required this.link, required this.website});
}

class _WebsiteArticlesListState extends State<WebsiteArticlesList> {
  List<RssItem> _rssItems = [];
  late String title;

  @override
  void initState() {
    super.initState();
    _fetchRss();
  }

  Future<void> _fetchRss() async {
    String link = widget.link;
    try {
      final response = await http.get(Uri.parse(link));
      if (response.statusCode == 200) {
        final feed = RssFeed.parse(response.body);

        // Link do strony głównej
        final channelLink = feed.link;

        setState(() {
          _rssItems = feed.items!;
          title = channelLink!;
        });
      } else {
        throw Exception('Failed to load RSS feed');
      }
    } catch (e) {
      print('Error fetching RSS feed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Wystąpił błąd podczas ładowania kanału RSS'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');

    return '${dateTime.day}.${dateTime.month}.${dateTime.year} '
        '${twoDigits(dateTime.hour)}:${twoDigits(dateTime.minute)}:${twoDigits(dateTime.second)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.website),
        ),
        body: _rssItems.isEmpty
            ? Center(
                child: CircularProgressIndicator(),
              )
            : ListView.builder(
                itemCount: _rssItems.length,
                itemBuilder: (context, index) {
                  final item = _rssItems[index];
                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      title: Text(
                        item.title ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        item.pubDate != null ? _formatDateTime(item.pubDate!) : '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WebViewPage(url: item.link ?? '', title: item.title ?? ''),
                          ),
                        );
                      },
                    ),
                  );
                },
              ));
  }
}

class WebViewPage extends StatelessWidget {
  final String url;
  final String title;

  WebViewPage({required this.url, required this.title});

  @override
  Widget build(BuildContext context) {
    WebViewController controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(url));

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
