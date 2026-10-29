import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/place.dart';
import 'package:flutter_application_1/models/weather.dart';
import 'package:flutter_application_1/screens/home_screen.dart';
import 'package:flutter_application_1/services/weather_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _place = Place(
  name: 'Ankara',
  region: 'Ankara',
  country: 'Turkey',
  latitude: 39.93,
  longitude: 32.85,
);

Map<String, dynamic> forecastJson() {
  final days = ['2024-01-10', '2024-01-11', '2024-01-12'];
  final hours = [
    for (final d in days)
      for (var h = 0; h < 24; h++) '${d}T${h.toString().padLeft(2, '0')}:00'
  ];
  return {
    'current': {
      'temperature_2m': -3.5,
      'weather_code': 71,
      'wind_speed_10m': 12
    },
    'hourly': {
      'time': hours,
      'temperature_2m': [for (var i = 0; i < hours.length; i++) -8 + i * 0.5],
      'weather_code': [for (var i = 0; i < hours.length; i++) 3],
      'wind_speed_10m': [for (var i = 0; i < hours.length; i++) 10],
    },
    'daily': {
      'time': days,
      'weather_code': [71, 3, 0],
      'temperature_2m_max': [1.0, 25.5, 4],
      'temperature_2m_min': [-9.0, 12.0, -2],
    },
  };
}

Future<http.Response> fakeHandler(http.Request request) async {
  switch (request.url.host) {
    case 'geocoding-api.open-meteo.com':
      final name = request.url.queryParameters['name'];
      if (name == 'nowhere') return http.Response('{}', 200);
      return http.Response.bytes(
          utf8.encode(jsonEncode({
            'results': [
              {
                'name': 'São Paulo',
                'admin1': 'São Paulo',
                'country': 'Brazil',
                'latitude': -23.5,
                'longitude': -46.6,
              }
            ]
          })),
          200);
    case 'api.open-meteo.com':
      return http.Response(jsonEncode(forecastJson()), 200);
    default:
      return http.Response('', 500);
  }
}

MockClient fakeApi() => MockClient(fakeHandler);

void main() {
  group('WeatherData.fromJson', () {
    final data = WeatherData.fromJson(forecastJson());

    test('keeps exactly the 24 hours of the first day, midnight included', () {
      expect(data.today, hasLength(24));
      expect(data.today.first.time.hour, 0);
      expect(data.today.last.time.hour, 23);
    });

    test('parses current and daily values, including ints', () {
      expect(data.current.temperature, -3.5);
      expect(data.current.windSpeed, 12.0);
      expect(data.week, hasLength(3));
      expect(data.week[2].maxTemperature, 4.0);
      expect(data.week[0].minTemperature, -9.0);
    });
  });

  group('Place', () {
    test('subtitle skips empty parts', () {
      const place =
          Place(name: 'X', region: '', country: 'Y', latitude: 0, longitude: 0);
      expect(place.subtitle, 'Y');
    });

    test('Nominatim reverse result uses province when state is missing', () {
      final place = Place.fromNominatim({
        'address': {'city': 'Ankara', 'province': 'Ankara', 'country': 'Turkey'}
      }, 39.9, 32.8);
      expect(place.name, 'Ankara');
      expect(place.subtitle, 'Ankara, Turkey');
    });
  });

  group('WeatherService', () {
    test('search query is URL encoded and parsed', () async {
      Uri? seen;
      final service = WeatherService(client: MockClient((request) async {
        seen = request.url;
        return fakeHandler(request);
      }));
      final results = await service.searchPlaces('São Paulo & co');
      expect(seen!.queryParameters['name'], 'São Paulo & co');
      expect(results.single.country, 'Brazil');
    });

    test('network failure becomes a readable WeatherException', () async {
      final service = WeatherService(
          client: MockClient((_) async => throw Exception('offline')));
      expect(
        () => service.fetchWeather(_place),
        throwsA(isA<WeatherException>().having(
            (e) => e.message, 'message', contains('connection is lost'))),
      );
    });
  });

  group('HomeScreen', () {
    Future<void> pumpHome(WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: HomeScreen(
          weatherService: WeatherService(client: fakeApi()),
          locateOnStart: false,
        ),
      ));
    }

    testWidgets('search, pick a city, see all three tabs', (tester) async {
      await pumpHome(tester);
      expect(find.textContaining('Search for a city'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'sao');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      await tester.tap(find.text('São Paulo, Brazil'));
      await tester.pumpAndSettle();

      // Currently
      expect(find.text('-3.5°C'), findsOneWidget);
      expect(find.text('Snowy'), findsOneWidget);
      expect(find.text('12.0 km/h'), findsOneWidget);

      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();
      expect(find.text("Today's temperatures"), findsOneWidget);

      await tester.tap(find.text('Weekly'));
      await tester.pumpAndSettle();
      expect(find.text('Weekly temperatures'), findsOneWidget);
      expect(find.text('Min'), findsOneWidget);
      expect(find.text('Max'), findsOneWidget);
    });

    testWidgets('unknown city shows the not-found message', (tester) async {
      await pumpHome(tester);
      await tester.enterText(find.byType(TextField), 'nowhere');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.textContaining('Could not find any result'), findsOneWidget);
    });
  });
}
