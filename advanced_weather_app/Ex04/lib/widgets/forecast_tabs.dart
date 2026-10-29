import 'package:flutter/material.dart';

import '../models/place.dart';
import '../models/weather.dart';
import '../utils/weather_codes.dart';
import 'common.dart';
import 'temperature_chart.dart';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String _hour(DateTime time) => '${time.hour.toString().padLeft(2, '0')}:00';

String _day(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

String _formatTemp(double value) => '${value.toStringAsFixed(1)}°C';

class CurrentlyTab extends StatelessWidget {
  final Place place;
  final WeatherData weather;

  const CurrentlyTab({super.key, required this.place, required this.weather});

  @override
  Widget build(BuildContext context) {
    final current = weather.current;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LocationHeader(place: place, titleSize: 30),
              const SizedBox(height: 28),
              Text(
                _formatTemp(current.temperature),
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                weatherDescription(current.weatherCode),
                style: const TextStyle(fontSize: 22, color: Colors.white),
              ),
              const SizedBox(height: 12),
              weatherIcon(current.weatherCode, size: 72),
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.air, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    '${current.windSpeed.toStringAsFixed(1)} km/h',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TodayTab extends StatelessWidget {
  final Place place;
  final WeatherData weather;

  const TodayTab({super.key, required this.place, required this.weather});

  @override
  Widget build(BuildContext context) {
    final hours = weather.today;
    if (hours.isEmpty) {
      return const InfoMessage(text: 'No hourly data available for today');
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          LocationHeader(place: place, titleSize: 22),
          const SizedBox(height: 12),
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
              child: Column(
                children: [
                  const Text("Today's temperatures",
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TemperatureChart(
                      series: [
                        ChartSeries(
                          label: 'Temperature',
                          color: Colors.orange,
                          values: [for (final h in hours) h.temperature],
                        ),
                      ],
                      bottomLabel: (i) => _hour(hours[i].time),
                      labelEvery: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: hours.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final h = hours[i];
                return _ForecastTile(
                  title: _hour(h.time),
                  icon: weatherIcon(h.weatherCode, size: 30),
                  lines: [
                    Text(_formatTemp(h.temperature),
                        style: const TextStyle(color: accentColor)),
                    Text('${h.windSpeed.toStringAsFixed(0)} km/h',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class WeeklyTab extends StatelessWidget {
  final Place place;
  final WeatherData weather;

  const WeeklyTab({super.key, required this.place, required this.weather});

  @override
  Widget build(BuildContext context) {
    final days = weather.week;
    if (days.isEmpty) {
      return const InfoMessage(text: 'No weekly data available');
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          LocationHeader(place: place, titleSize: 22),
          const SizedBox(height: 12),
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
              child: Column(
                children: [
                  const Text('Weekly temperatures',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TemperatureChart(
                      series: [
                        ChartSeries(
                          label: 'Min',
                          color: Colors.lightBlueAccent,
                          values: [for (final d in days) d.minTemperature],
                        ),
                        ChartSeries(
                          label: 'Max',
                          color: Colors.redAccent,
                          values: [for (final d in days) d.maxTemperature],
                        ),
                      ],
                      bottomLabel: (i) => _day(days[i].date),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final d = days[i];
                return _ForecastTile(
                  title: '${_weekdays[d.date.weekday - 1]} ${_day(d.date)}',
                  icon: weatherIcon(d.weatherCode, size: 30),
                  lines: [
                    Text(weatherDescription(d.weatherCode),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                    Text(_formatTemp(d.maxTemperature),
                        style: const TextStyle(color: Colors.redAccent)),
                    Text(_formatTemp(d.minTemperature),
                        style: const TextStyle(color: Colors.lightBlueAccent)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ForecastTile extends StatelessWidget {
  final String title;
  final Widget icon;
  final List<Widget> lines;

  const _ForecastTile(
      {required this.title, required this.icon, required this.lines});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        // Shrinks on small screens or large system fonts instead of overflowing.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
              const SizedBox(height: 6),
              icon,
              const SizedBox(height: 6),
              ...lines,
            ],
          ),
        ),
      ),
    );
  }
}
