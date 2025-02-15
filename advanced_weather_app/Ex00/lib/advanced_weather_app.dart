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
  String location = "";
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String? _errorMessage;

  Timer? _debounceTimer;

  Map<String, dynamic>? _currentWeatherData;
  Map<String, dynamic>? _hourlyWeatherData;
  Map<String, dynamic>? _dailyWeatherData;
  String _cityName = "";
  String _region = "";
  String _country = "";
  bool _locationPermissionDenied = false;

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
    if (_locationPermissionDenied) {
      setState(() => _errorMessage = "Location permission denied. Please allow in settings.");
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/search?format=json&q=$query'),
        headers: {'User-Agent': 'YourAppName/1.0'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isEmpty) {
          setState(() => _errorMessage = "Belirtilen adres veya koordinatlar için sonuç bulunamadı");
        } else {
          setState(() => _searchResults = data
              .map((item) => {
                    'name': item['display_name'],
                    'lat': item['lat'],
                    'lon': item['lon'],
                  })
              .toList());
        }
      }
    } on TimeoutException {
      setState(() => _errorMessage =
          "Bağlantı zaman aşımına uğradı, lütfen internet bağlantınızı kontrol edin veya daha sonra tekrar deneyin");
    } catch (e) {
      setState(() => _errorMessage =
          "Servis bağlantısı kesildi, lütfen internet bağlantınızı kontrol edin veya daha sonra tekrar deneyin");
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _fetchWeatherData(double lat, double lon) async {
    try {
      final response = await http
          .get(
            Uri.parse(
                'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true&hourly=temperature_2m,weathercode,windspeed_10m&daily=weathercode,temperature_2m_max,temperature_2m_min'),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          _currentWeatherData = json.decode(response.body)['current_weather'];
          _hourlyWeatherData = json.decode(response.body)['hourly'];
          _dailyWeatherData = json.decode(response.body)['daily'];
          _errorMessage = null;
        });
      }
    } on TimeoutException {
      setState(() => _errorMessage =
          "Bağlantı zaman aşımına uğradı, lütfen internet bağlantınızı kontrol edin veya daha sonra tekrar deneyin");
    } catch (e) {
      setState(() => _errorMessage =
          "Servis bağlantısı kesildi, lütfen internet bağlantınızı kontrol edin veya daha sonra tekrar deneyin");
    }
  }

  void _onLocationSelected(Map<String, dynamic> location) async {
    final lat = double.parse(location['lat']);
    final lon = double.parse(location['lon']);
    final nameParts = location['name'].split(',');

    setState(() {
      _cityName = nameParts[0].trim();
      _region = nameParts.length > 1 ? nameParts[1].trim() : '';
      _country = nameParts.length > 2 ? nameParts[2].trim() : '';
      _controller.text = location['name'];
      _searchResults = [];
    });

    await _fetchWeatherData(lat, lon);
  }

  Future<void> _getCurrentLocation() async {
    if (_locationPermissionDenied) {
      setState(() {
        _errorMessage = "";
      });
      return;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _errorMessage = "";
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _errorMessage = "";
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationPermissionDenied = true; 
        _errorMessage = "Servis bağlantısı kesildi, lütfen internet bağlantınızı kontrol edin veya daha sonra tekrar deneyin";
      });
      return;
    }
  }

  String _getWeatherDescription(int weatherCode) {
    switch (weatherCode) {
      case 0:
        return "Açık";
      case 1:
        return "Çoğunlukla açık";
      case 2:
        return "Parçalı bulutlu";
      case 3:
        return "Bulutlu";
      case 45:
      case 48:
        return "Sisli";
      case 51:
      case 53:
      case 55:
        return "Çiseleyen yağmur";
      case 56:
      case 57:
        return "Donan çisenti";
      case 61:
      case 63:
      case 65:
        return "Yağmurlu";
      case 66:
      case 67:
        return "Donan yağmur";
      case 71:
      case 73:
      case 75:
        return "Karlı";
      case 77:
        return "Kar taneleri";
      case 80:
      case 81:
      case 82:
        return "Sağanak yağış";
      case 85:
      case 86:
        return "Kar fırtınası";
      case 95:
      case 96:
      case 99:
        return "Fırtınalı";
      default:
        return "Bilinmeyen";
    }
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
                        hintText: 'Şehir ara...',
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
                tooltip: 'Konumumu Bul',
                icon: const Icon(Icons.location_searching_sharp, size: 28),
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
                    if (_cityName.isNotEmpty)
                      Column(
                        children: [
                          Text(
                            _cityName,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '$_region, $_country',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    if (_currentWeatherData != null)
                      Column(
                        children: [
                          Text(
                            'Sıcaklık: ${_currentWeatherData!['temperature']}°C',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Hava Durumu: ${_getWeatherDescription(_currentWeatherData!['weathercode'])}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Rüzgar Hızı: ${_currentWeatherData!['windspeed']} km/sa',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                  ],
                ),
                Column(
                  children: [
                    if (_cityName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              _cityName,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '$_region, $_country',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    if (_hourlyWeatherData != null)
                      Expanded(
                        child: ListView.builder(
                          itemCount: 24,
                          itemBuilder: (context, index) {
                            final time = _hourlyWeatherData!['time'][index];
                            final temperature = _hourlyWeatherData!['temperature_2m'][index];
                            final weatherCode = _hourlyWeatherData!['weathercode'][index];
                            final windSpeed = _hourlyWeatherData!['windspeed_10m'][index];

                            return ListTile(
                              title: Text(DateTime.parse(time).toString()),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Sıcaklık: $temperature°C'),
                                  Text('Hava Durumu: ${_getWeatherDescription(weatherCode)}'),
                                  Text('Rüzgar Hızı: $windSpeed km/sa'),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
                // Weekly tab
                Column(
                  children: [
                    if (_cityName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              _cityName,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '$_region, $_country',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    if (_dailyWeatherData != null)
                      Expanded(
                        child: ListView.builder(
                          itemCount: _dailyWeatherData!['time'].length,
                          itemBuilder: (context, index) {
                            final date = _dailyWeatherData!['time'][index];
                            final maxTemp = _dailyWeatherData!['temperature_2m_max'][index];
                            final minTemp = _dailyWeatherData!['temperature_2m_min'][index];
                            final weatherCode = _dailyWeatherData!['weathercode'][index];

                            return ListTile(
                              title: Text(date),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Max Sıcaklık: $maxTemp°C'),
                                  Text('Min Sıcaklık: $minTemp°C'),
                                  Text('Hava Durumu: ${_getWeatherDescription(weatherCode)}'),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
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
                    // Maksimum 5 öneri gösteriliyor.
                    itemCount: _searchResults.length > 5 ? 5 : _searchResults.length,
                    itemBuilder: (context, index) {
                      final result = _searchResults[index];
                      return ListTile(
                        title: Text(result['name']),
                        onTap: () {
                          _onLocationSelected(result);
                          _searchResults.clear();
                          _controller.text = "";
                        },
                      );
                    },
                  ),
                ),
              ),
            if (_errorMessage != null || location.isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    location.isNotEmpty ? location : _errorMessage ?? "",
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
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
