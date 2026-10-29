class CurrentWeather {
  final double temperature;
  final int weatherCode;
  final double windSpeed;

  const CurrentWeather({
    required this.temperature,
    required this.weatherCode,
    required this.windSpeed,
  });
}

class HourlyWeather {
  final DateTime time;
  final double temperature;
  final int weatherCode;
  final double windSpeed;

  const HourlyWeather({
    required this.time,
    required this.temperature,
    required this.weatherCode,
    required this.windSpeed,
  });
}

class DailyWeather {
  final DateTime date;
  final double minTemperature;
  final double maxTemperature;
  final int weatherCode;

  const DailyWeather({
    required this.date,
    required this.minTemperature,
    required this.maxTemperature,
    required this.weatherCode,
  });
}

class WeatherData {
  final CurrentWeather current;

  /// Hourly forecast for the first day only, in the location's local time.
  final List<HourlyWeather> today;
  final List<DailyWeather> week;

  const WeatherData({
    required this.current,
    required this.today,
    required this.week,
  });

  /// Parses an Open-Meteo forecast response requested with `timezone=auto`,
  /// so every timestamp is already in the location's local time.
  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>;
    final hourly = json['hourly'] as Map<String, dynamic>;
    final daily = json['daily'] as Map<String, dynamic>;

    final dailyTimes = List<String>.from(daily['time'] as List);
    final week = [
      for (var i = 0; i < dailyTimes.length; i++)
        DailyWeather(
          date: DateTime.parse(dailyTimes[i]),
          minTemperature: _toDouble(daily['temperature_2m_min'][i]),
          maxTemperature: _toDouble(daily['temperature_2m_max'][i]),
          weatherCode: _toInt(daily['weather_code'][i]),
        ),
    ];

    // Hourly times look like "2024-10-29T00:00"; the first daily entry is
    // today's date, so keep only the hours starting with it.
    final todayPrefix = dailyTimes.isNotEmpty ? dailyTimes.first : '';
    final hourlyTimes = List<String>.from(hourly['time'] as List);
    final today = [
      for (var i = 0; i < hourlyTimes.length; i++)
        if (hourlyTimes[i].startsWith(todayPrefix))
          HourlyWeather(
            time: DateTime.parse(hourlyTimes[i]),
            temperature: _toDouble(hourly['temperature_2m'][i]),
            weatherCode: _toInt(hourly['weather_code'][i]),
            windSpeed: _toDouble(hourly['wind_speed_10m'][i]),
          ),
    ];

    return WeatherData(
      current: CurrentWeather(
        temperature: _toDouble(current['temperature_2m']),
        weatherCode: _toInt(current['weather_code']),
        windSpeed: _toDouble(current['wind_speed_10m']),
      ),
      today: today,
      week: week,
    );
  }

  static double _toDouble(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  static int _toInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? -1;
}
