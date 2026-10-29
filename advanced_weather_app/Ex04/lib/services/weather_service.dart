import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/place.dart';
import '../models/weather.dart';

class WeatherException implements Exception {
  final String message;
  const WeatherException(this.message);

  static const connection = WeatherException(
      'The service connection is lost, please check your internet connection or try again later');
  static const notFound = WeatherException(
      'Could not find any result for the supplied address or coordinates');

  @override
  String toString() => message;
}

/// Talks to Open-Meteo (geocoding + forecast) and Nominatim (reverse lookup).
class WeatherService {
  static const _timeout = Duration(seconds: 10);
  final http.Client _client;

  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Place>> searchPlaces(String query, {int count = 5}) async {
    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': query,
      'count': '$count',
      'language': 'en',
      'format': 'json',
    });
    final json = await _getJson(uri);
    final results = (json['results'] as List?) ?? const [];
    return results
        .map((item) => Place.fromOpenMeteo(item as Map<String, dynamic>))
        .toList();
  }

  Future<Place> reverseGeocode(double latitude, double longitude) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'json',
      'lat': '$latitude',
      'lon': '$longitude',
      'zoom': '10',
      'accept-language': 'en',
    });
    try {
      final json = await _getJson(uri,
          headers: {'User-Agent': 'FlutterExamplesWeatherApp/1.0'});
      return Place.fromNominatim(json, latitude, longitude);
    } on WeatherException {
      // The forecast still works without a name, so fall back to coordinates.
      return Place(
        name: 'Current location',
        region:
            '${latitude.toStringAsFixed(2)}, ${longitude.toStringAsFixed(2)}',
        country: '',
        latitude: latitude,
        longitude: longitude,
      );
    }
  }

  Future<WeatherData> fetchWeather(Place place) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '${place.latitude}',
      'longitude': '${place.longitude}',
      'current': 'temperature_2m,weather_code,wind_speed_10m',
      'hourly': 'temperature_2m,weather_code,wind_speed_10m',
      'daily': 'weather_code,temperature_2m_max,temperature_2m_min',
      'timezone': 'auto',
      'forecast_days': '7',
    });
    final json = await _getJson(uri);
    try {
      return WeatherData.fromJson(json);
    } catch (_) {
      throw WeatherException.connection;
    }
  }

  Future<Map<String, dynamic>> _getJson(Uri uri,
      {Map<String, String>? headers}) async {
    try {
      final response =
          await _client.get(uri, headers: headers).timeout(_timeout);
      if (response.statusCode != 200) throw WeatherException.connection;
      // Decode as UTF-8 explicitly so names like "São Paulo" are never garbled.
      return json.decode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
    } on WeatherException {
      rethrow;
    } catch (_) {
      throw WeatherException.connection;
    }
  }
}
