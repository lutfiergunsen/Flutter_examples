import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

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
  String location = "location not found";
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_controller.text.isNotEmpty) {
        _searchLocation(_controller.text);
      } else {
        setState(() => _searchResults = []);
      }
    });
  }

  Future<void> _searchLocation(String query) async {
    setState(() => _isSearching = true);
    try {
      final response = await http.get(
        Uri.parse(
            'https://nominatim.openstreetmap.org/search?format=json&q=$query'),
        headers: {'User-Agent': 'YourAppName/1.0'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _searchResults = data
              .map((item) => {
                    'name': item['display_name'],
                    'lat': item['lat'],
                    'lon': item['lon'],
                  })
              .toList();
        });
      }
    } catch (e) {
      print('search error: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _onLocationSelected(Map<String, dynamic> selectedLocation) {
    setState(() {
      location =
          "Lat: ${selectedLocation['lat']}, Lng: ${selectedLocation['lon']}";
      _controller.text = selectedLocation['name'];
      _searchResults = [];
    });
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        location = "Location service is disabled.";
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          location = "Location permission denied.";
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        location =
            "Geolocation is not available, please enable it in your App settings";
      });
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      location = "Lat: ${position.latitude}, Lng: ${position.longitude}";
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
                child: Column(
                  children: [
                    TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Search city...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                    ),
                    if (_isSearching)
                      const LinearProgressIndicator(
                        color: Colors.blue,
                        minHeight: 2,
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.location_searching_sharp),
                onPressed: _getCurrentLocation,
              ),
            ],
          ),
          backgroundColor: Colors.blue,
        ),
        body: Stack(
          children: [
            TabBarView(
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
            if (_searchResults.isNotEmpty)
              Positioned(
                top: 60,
                left: 20,
                right: 20,
                child: Material(
                  elevation: 4,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final result = _searchResults[index];
                      return ListTile(
                        title: Text(result['name']),
                        onTap: () => _onLocationSelected(result),
                      );
                    },
                  ),
                ),
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
