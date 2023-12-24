// SettingsPage.dart
import 'package:flutter/material.dart';
import 'package:rss_reader/database_helper.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDarkModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadDarkMode();
  }

  void _loadDarkMode() async {
    final bool isDarkMode = await DatabaseHelper.getDarkMode();
    setState(() {
      _isDarkModeEnabled = isDarkMode;
    });
  }

  void _toggleDarkMode(bool value) async {
    await DatabaseHelper.setDarkMode(value);
    _loadDarkMode();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ustawienia'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Motyw:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SwitchListTile(
              title: Text('Tryb ciemny'),
              value: _isDarkModeEnabled,
              onChanged: (value) {
                _toggleDarkMode(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
