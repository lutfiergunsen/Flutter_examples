import 'dart:async';

import 'package:flutter/material.dart';

import '../models/place.dart';
import '../models/weather.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';
import '../widgets/common.dart';
import '../widgets/forecast_tabs.dart';

class HomeScreen extends StatefulWidget {
  final WeatherService? weatherService;
  final LocationService? locationService;

  /// Ask for the device location as soon as the screen opens.
  final bool locateOnStart;

  const HomeScreen({
    super.key,
    this.weatherService,
    this.locationService,
    this.locateOnStart = true,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final WeatherService _weatherService =
      widget.weatherService ?? WeatherService();
  late final LocationService _locationService =
      widget.locationService ?? LocationService();

  final _searchController = TextEditingController();
  Timer? _debounce;

  /// Increases with every search so late responses of older queries are ignored.
  int _searchId = 0;
  List<Place> _results = [];
  bool _searching = false;

  Place? _place;
  WeatherData? _weather;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.locateOnStart) _useCurrentLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // Called only for user typing, not for programmatic text changes, so
  // selecting a result does not start another search.
  void _onSearchChanged(String text) {
    _debounce?.cancel();
    if (text.trim().isEmpty) {
      _searchId++;
      setState(() {
        _results = [];
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(text));
  }

  Future<List<Place>> _search(String text) async {
    final id = ++_searchId;
    setState(() => _searching = true);
    try {
      final results = await _weatherService.searchPlaces(text.trim());
      if (!mounted || id != _searchId) return results;
      setState(() {
        _results = results;
        _error = results.isEmpty ? WeatherException.notFound.message : null;
      });
      return results;
    } on WeatherException catch (e) {
      if (mounted && id == _searchId) {
        setState(() {
          _results = [];
          _error = e.message;
        });
      }
      return const [];
    } finally {
      if (mounted && id == _searchId) setState(() => _searching = false);
    }
  }

  Future<void> _onSubmitted(String text) async {
    _debounce?.cancel();
    if (text.trim().isEmpty) return;
    final results = _results.isNotEmpty ? _results : await _search(text);
    if (results.isNotEmpty) _selectPlace(results.first);
  }

  void _selectPlace(Place place) {
    _searchId++;
    _searchController.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _results = [];
      _searching = false;
    });
    _loadWeather(place);
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final position = await _locationService.currentPosition();
      final place = await _weatherService.reverseGeocode(
          position.latitude, position.longitude);
      await _loadWeather(place);
    } on LocationException catch (e) {
      _showError(e.message);
    } on WeatherException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Could not get your location. Please search for a city.');
    }
  }

  Future<void> _loadWeather(Place place) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final weather = await _weatherService.fetchWeather(place);
      if (!mounted) return;
      setState(() {
        _place = place;
        _weather = weather;
        _loading = false;
      });
    } on WeatherException catch (e) {
      _showError(e.message);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black87,
          titleSpacing: 12,
          title: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            onSubmitted: _onSubmitted,
            textInputAction: TextInputAction.search,
            style: const TextStyle(color: Colors.black87),
            cursorColor: Colors.black87,
            decoration: InputDecoration(
              hintText: 'Search city...',
              hintStyle: const TextStyle(color: Colors.black45),
              prefixIcon: const Icon(Icons.search, color: Colors.black54),
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Use my location',
              color: accentColor,
              icon: const Icon(Icons.my_location),
              onPressed: _loading ? null : _useCurrentLocation,
            ),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/weather_app.jpg',
                fit: BoxFit.cover,
                color: Colors.black38,
                colorBlendMode: BlendMode.darken,
              ),
            ),
            _buildContent(),
            if (_results.isNotEmpty) _buildResults(),
          ],
        ),
        bottomNavigationBar: Container(
          color: Colors.black54,
          child: const SafeArea(
            top: false,
            child: TabBar(
              labelColor: accentColor,
              unselectedLabelColor: Colors.white,
              indicatorColor: accentColor,
              tabs: [
                Tab(icon: Icon(Icons.wb_sunny_outlined), text: 'Currently'),
                Tab(icon: Icon(Icons.today), text: 'Today'),
                Tab(icon: Icon(Icons.date_range), text: 'Weekly'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: accentColor));
    }

    final place = _place;
    final weather = _weather;
    final error = _error;

    if (place == null || weather == null) {
      return InfoMessage(
        text: error ??
            'Search for a city or tap the location button to see the weather.',
        icon: error == null ? Icons.search : Icons.error_outline,
        color: error == null ? Colors.white : Colors.redAccent,
      );
    }

    return Column(
      children: [
        if (error != null)
          Container(
            width: double.infinity,
            color: Colors.red.withOpacity(0.8),
            padding: const EdgeInsets.all(8),
            child: Text(error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white)),
          ),
        Expanded(
          child: TabBarView(
            children: [
              CurrentlyTab(place: place, weather: weather),
              TodayTab(place: place, weather: weather),
              WeeklyTab(place: place, weather: weather),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResults() {
    return Positioned(
      top: 0,
      left: 12,
      right: 12,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: _results.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final place = _results[i];
            return ListTile(
              dense: true,
              leading: const Icon(Icons.location_city),
              title: Text(place.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(place.subtitle),
              onTap: () => _selectPlace(place),
            );
          },
        ),
      ),
    );
  }
}
