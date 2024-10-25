
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

class TabBarExample extends StatefulWidget {
  const TabBarExample({super.key});

  @override
  TabBarExamplesState createState() => TabBarExamplesState();
}
class TabBarExamplesState extends State<TabBarExample> {
  final TextEditingController _controller = TextEditingController();
  String location = "";

  void _updateLocation() {
    setState(() {
      location = _controller.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.location_searching_sharp),
                onPressed: _updateLocation,
              ),
            ],
          ),
          backgroundColor: Colors.blue,
        ),
        body: TabBarView(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Currently"),
                Text(location),
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Today"),
                Text(location),
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Weekly"),
                Text(location),
              ],
            ),
          ],
        ),
        bottomNavigationBar: const BottomAppBar(
          child: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.calendar_today), text: "Currently"),
              Tab(icon: Icon(Icons.calendar_view_day), text: "Today"),
              Tab(icon: Icon(Icons.calendar_view_week), text: "Weekly"),
            ],
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.black,
            indicatorColor: Colors.blue,
          ),
        ),
      ),
    );
  }
}
  