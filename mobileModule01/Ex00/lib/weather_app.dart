import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: TabBarExample(),
    );
  }
}

class TabBarExample extends StatelessWidget {
  const TabBarExample({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
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
        bottomNavigationBar: const BottomAppBar(
          child: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.calendar_today), text: "Currently"),
              Tab(icon: Icon(Icons.calendar_view_day), text: "Today"),
              Tab(icon: Icon(Icons.calendar_view_week), text: "Weekly"),
            ],
            labelColor: Colors.green,
            unselectedLabelColor: Colors.black,
            indicatorColor: Colors.green,
          ),
        ),
      ),
    );
  }
}
