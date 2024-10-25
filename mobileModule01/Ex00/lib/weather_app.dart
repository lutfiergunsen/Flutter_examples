import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TabBarExample(),
    );
  }
}

class TabBarExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Sekme sayısını belirtir
      child: Scaffold(
        appBar: AppBar(
          title: const Text(''),
        ),
        body: const TabBarView(
          children: [
            Center(child: Text("Currently")),
            Center(child: Text("Today")),
            Center(child: Text("Weekly")),
          ],
        ),
        bottomNavigationBar: const TabBar(
          tabs: [
            Tab(icon: Icon(Icons.calendar_today), text: "Currently"),
            Tab(icon: Icon(Icons.calendar_view_day), text: "Today"),
            Tab(icon: Icon(Icons.calendar_view_week), text: "Weekly"),
          ],
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
        ),
      ),
    );
  }
}
