import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';

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
  
  // Bugünün verilerini tutmak için yeni değişkenler
  List<dynamic>? _todayHourlyTimes;
  List<dynamic>? _todayHourlyTemperatures;
  List<dynamic>? _todayHourlyWeatherCodes;
  List<dynamic>? _todayHourlyWindSpeeds;

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
      setState(() => _errorMessage =
          "Location permission denied. Please allow in settings.");
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://nominatim.openstreetmap.org/search?format=json&q=$query'),
        headers: {'User-Agent': 'YourAppName/1.0'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isEmpty) {
          setState(() => _errorMessage =
              "Could not find any result for the supplied address or coordinates");
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
          "The service connection is lost, please check your internet connection or try again later");
    } catch (e) {
      setState(() => _errorMessage =
          "The service connection is lost, please check your internet connection or try again later");
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
        final data = json.decode(response.body);
        
        setState(() {
          _currentWeatherData = data['current_weather'];
          _hourlyWeatherData = data['hourly'];
          _dailyWeatherData = data['daily'];
          _errorMessage = null;
          
          // Bugünün verilerini filtrele
          _extractTodayHourlyData();
        });
      }
    } on TimeoutException {
      setState(() => _errorMessage =
          "The service connection is lost, please check your internet connection or try again later");
    } catch (e) {
      setState(() => _errorMessage =
          "The service connection is lost, please check your internet connection or try again later");
    }
  }
  
  // Bugünün saatlik verilerini ayıklayan yeni metot
  void _extractTodayHourlyData() {
    if (_hourlyWeatherData == null) return;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    // Bugüne ait saat, sıcaklık, hava durumu kodu ve rüzgar hızı verilerini ayıkla
    List<dynamic> times = [];
    List<dynamic> temperatures = [];
    List<dynamic> weatherCodes = [];
    List<dynamic> windSpeeds = [];
    
    for (int i = 0; i < (_hourlyWeatherData!['time'] as List).length; i++) {
      final timeStr = _hourlyWeatherData!['time'][i];
      final time = DateTime.parse(timeStr);
      
      // Sadece bugünün verilerini al
      if (time.isAfter(today) && time.isBefore(tomorrow)) {
        times.add(timeStr);
        temperatures.add(_hourlyWeatherData!['temperature_2m'][i]);
        weatherCodes.add(_hourlyWeatherData!['weathercode'][i]);
        windSpeeds.add(_hourlyWeatherData!['windspeed_10m'][i]);
      }
    }
    
    _todayHourlyTimes = times;
    _todayHourlyTemperatures = temperatures;
    _todayHourlyWeatherCodes = weatherCodes;
    _todayHourlyWindSpeeds = windSpeeds;
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
        _errorMessage =
            "The service connection is lost, please check your internet connection or try again later";
      });
      return;
    }
  }

  String _getWeatherDescription(int weatherCode) {
    switch (weatherCode) {
      case 0:
        return "Clear";
      case 1:
        return "Mostly clear";
      case 2:
        return "Partly cloudy";
      case 3:
        return "Cloudy";
      case 45:
      case 48:
        return "Foggy";
      case 51:
      case 53:
      case 55:
        return "Drizzling rain";
      case 56:
      case 57:
        return "Freezing drizzle";
      case 61:
      case 63:
      case 65:
        return "Rainy";
      case 66:
      case 67:
        return "Freezing rain";
      case 71:
      case 73:
      case 75:
        return "Snowy";
      case 77:
        return "Snowflakes";
      case 80:
      case 81:
      case 82:
        return "Showers";
      case 85:
      case 86:
        return "Snowstorm";
      case 95:
      case 96:
      case 99:
        return "Stormy";
      default:
        return "Unknown";
    }
  }

  Icon _getWeatherIcon(int weatherCode, double size) {
    switch (weatherCode) {
      case 0:
        return Icon(Icons.wb_sunny, color: Colors.orange, size: size);
      case 1:
      case 2:
        return Icon(Icons.wb_cloudy, color: Colors.amber, size: size);
      case 3:
        return Icon(Icons.cloud, color: Colors.grey, size: size);
      case 45:
      case 48:
        return Icon(Icons.cloudy_snowing, color: Colors.grey, size: size);
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        return Icon(Icons.grain, color: Colors.blue, size: size);
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
        return Icon(Icons.umbrella, color: Colors.blue, size: size);
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return Icon(Icons.ac_unit, color: Colors.blue, size: size);
      case 80:
      case 81:
      case 82:
      case 95:
      case 96:
      case 99:
        return Icon(Icons.thunderstorm, color: Colors.deepPurple, size: size);
      default:
        return Icon(Icons.help_outline, color: Colors.white, size: size);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 0, 255, 0),
          elevation: 0,
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
                        fillColor: Colors.white,
                      ),
                    ),
                    if (_isSearching)
                      const LinearProgressIndicator(
                        color: Colors.black,
                        minHeight: 2,
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Search',
                icon: const Icon(Icons.location_searching_sharp, size: 28),
                onPressed: _getCurrentLocation,
              ),
            ],
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/weather_app.jpg"),
                    fit: BoxFit.cover,
                    colorFilter:
                        ColorFilter.mode(Colors.black26, BlendMode.darken),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: TabBarView(
                children: [
                  // Currently tab
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_cityName.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.location_on,
                                      color: Colors.white, size: 28),
                                  const SizedBox(width: 8),
                                  Column(
                                    children: [
                                      Text(
                                        _cityName,
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        '$_region, $_country',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 30),
                              if (_currentWeatherData != null)
                                Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        _getWeatherIcon(
                                            _currentWeatherData!['weathercode'],
                                            64),
                                        const SizedBox(width: 20),
                                        Text(
                                          '${_currentWeatherData!['temperature']}°C',
                                          style: const TextStyle(
                                            fontSize: 48,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      _getWeatherDescription(
                                          _currentWeatherData!['weathercode']),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        color: Colors.white,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    const SizedBox(height: 30),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.air,
                                              color: Colors.white, size: 28),
                                          const SizedBox(width: 10),
                                          Text(
                                            '${_currentWeatherData!['windspeed']} km/h',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  // Today tab - Bugüne ait veriler için güncellenmiş kod
                  Column(
                    children: [
                      if (_cityName.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                _cityName,
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              Text(
                                '$_region, $_country',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      if (_todayHourlyTemperatures != null && _todayHourlyTemperatures!.isNotEmpty)
                        Container(
                          height: 300,
                          padding: const EdgeInsets.all(16.0),
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(show: true),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      if (value.toInt() >= 0 && 
                                          value.toInt() < _todayHourlyTimes!.length) {
                                        final timeStr = _todayHourlyTimes![value.toInt()];
                                        final hour = DateTime.parse(timeStr).hour;
                                        return Text(
                                          '$hour:00',
                                          style: const TextStyle(
                                              color: Colors.white, fontSize: 10),
                                        );
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 2,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        '${value.toInt()}°C',
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 10),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: true),
                              minX: 0,
                              maxX: (_todayHourlyTemperatures!.length - 1).toDouble(),
                              minY: 0,
                              maxY: 20, // Verilere göre dinamik ayarlanabilir
                              lineBarsData: [
                                LineChartBarData(
                                  spots: List<FlSpot>.from(
                                    _todayHourlyTemperatures!
                                        .asMap()
                                        .entries
                                        .map((entry) => FlSpot(
                                              entry.key.toDouble(),
                                              (entry.value is num)
                                                  ? entry.value.toDouble()
                                                  : double.tryParse(entry.value
                                                          .toString()) ??
                                                      0.0,
                                            )),
                                  ),
                                  isCurved: true,
                                  color: Colors.orange,
                                  dotData: FlDotData(show: false),
                                  belowBarData: BarAreaData(show: false),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 200,
                          padding: const EdgeInsets.all(16.0),
                          child: const Center(
                            child: Text(
                              'Loading weather data...',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ),
                      Expanded(
                        child: _todayHourlyTimes == null
                            ? const Center(
                                child: Text(
                                  'No data available for today',
                                  style: TextStyle(color: Colors.white, fontSize: 16),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _todayHourlyTimes!.length,
                                itemBuilder: (context, index) {
                                  final time = _todayHourlyTimes![index];
                                  final temperature = _todayHourlyTemperatures![index];
                                  final weatherCode = _todayHourlyWeatherCodes![index];
                                  final windSpeed = _todayHourlyWindSpeeds![index];

                                  return ListTile(
                                    title: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          time != null
                                              ? '${DateTime.parse(time).hour}:00'
                                              : 'N/A',
                                          style: const TextStyle(
                                              color: Colors.white, fontSize: 16),
                                        ),
                                        Row(
                                          children: [
                                            if (weatherCode != null)
                                              _getWeatherIcon(weatherCode, 24),
                                            const SizedBox(width: 8),
                                            Text(
                                              weatherCode != null
                                                  ? '${_getWeatherDescription(weatherCode)}'
                                                  : 'N/A',
                                              style: const TextStyle(
                                                  color: Colors.white, fontSize: 16),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          temperature != null
                                              ? (temperature is num)
                                                  ? '$temperature°C'
                                                  : '${double.tryParse(temperature.toString()) ?? 'N/A'}°C'
                                              : 'N/A',
                                          style: const TextStyle(
                                              color: Colors.white, fontSize: 16),
                                        ),
                                        Text(
                                          windSpeed != null
                                              ? (windSpeed is num)
                                                  ? '$windSpeed km/h'
                                                  : '${double.tryParse(windSpeed.toString()) ?? 'N/A'} km/h'
                                              : 'N/A',
                                          style: const TextStyle(
                                              color: Colors.white, fontSize: 16),
                                        ),
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_cityName.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                _cityName,
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              Text(
                                '$_region, $_country',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
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
                              final maxTemp =
                                  _dailyWeatherData!['temperature_2m_max']
                                      [index];
                              final minTemp =
                                  _dailyWeatherData!['temperature_2m_min']
                                      [index];
                              final weatherCode =
                                  _dailyWeatherData!['weathercode'][index];

                              return ListTile(
                                subtitle: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(date,
                                        style: const TextStyle(
                                            color: Colors.white)),
                                    Text('Max Temperature: $maxTemp°C',
                                        style: const TextStyle(
                                            color: Colors.white)),
                                    Text('Min Temperature: $minTemp°C',
                                        style: const TextStyle(
                                            color: Colors.white)),
                                    Text(
                                        'Hava Durumu: ${_getWeatherDescription(weatherCode)}',
                                        style: const TextStyle(
                                            color: Colors.white)),
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
            ),
            if (_searchResults.isNotEmpty)
              Positioned(
                top: 0,
                left: 20,
                right: 20,
                child: Material(
                  elevation: 4,
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.5,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (int i = 0;
                              i <
                                  (_searchResults.length > 5
                                      ? 5
                                      : _searchResults.length);
                              i++)
                            ListTile(
                              dense: true,
                              title: Text(_searchResults[i]['name']),
                              onTap: () {
                                _onLocationSelected(_searchResults[i]);
                                _searchResults = [];
                                _controller.text = "";
                              },
                            ),
                        ],
                      ),
                    ),
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
          color: Colors.transparent,
          elevation: 0,
          child: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.calendar_today), text: "Currently"),
              Tab(icon: Icon(Icons.calendar_view_day), text: "Today"),
              Tab(icon: Icon(Icons.calendar_view_week), text: "Weekly"),
            ],
            labelColor: Color.fromARGB(255, 0, 255, 0),
            unselectedLabelColor: Colors.white,
            indicatorColor: Color.fromARGB(255, 0, 255, 0),
          ),
        ),
      ),
    );
  }
}