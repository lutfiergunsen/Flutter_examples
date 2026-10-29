import 'package:flutter/material.dart';

/// Human readable text for a WMO weather code used by Open-Meteo.
String weatherDescription(int code) {
  switch (code) {
    case 0:
      return 'Clear';
    case 1:
      return 'Mostly clear';
    case 2:
      return 'Partly cloudy';
    case 3:
      return 'Cloudy';
    case 45:
    case 48:
      return 'Foggy';
    case 51:
    case 53:
    case 55:
      return 'Drizzle';
    case 56:
    case 57:
      return 'Freezing drizzle';
    case 61:
    case 63:
    case 65:
      return 'Rainy';
    case 66:
    case 67:
      return 'Freezing rain';
    case 71:
    case 73:
    case 75:
      return 'Snowy';
    case 77:
      return 'Snow grains';
    case 80:
    case 81:
    case 82:
      return 'Showers';
    case 85:
    case 86:
      return 'Snow showers';
    case 95:
    case 96:
    case 99:
      return 'Thunderstorm';
    default:
      return 'Unknown';
  }
}

Icon weatherIcon(int code, {double size = 24}) {
  switch (code) {
    case 0:
      return Icon(Icons.wb_sunny, color: Colors.orange, size: size);
    case 1:
    case 2:
      return Icon(Icons.wb_cloudy, color: Colors.amber, size: size);
    case 3:
      return Icon(Icons.cloud, color: Colors.blueGrey.shade100, size: size);
    case 45:
    case 48:
      return Icon(Icons.foggy, color: Colors.blueGrey.shade100, size: size);
    case 51:
    case 53:
    case 55:
    case 56:
    case 57:
      return Icon(Icons.grain, color: Colors.lightBlue, size: size);
    case 61:
    case 63:
    case 65:
    case 66:
    case 67:
    case 80:
    case 81:
    case 82:
      return Icon(Icons.umbrella, color: Colors.lightBlue, size: size);
    case 71:
    case 73:
    case 75:
    case 77:
    case 85:
    case 86:
      return Icon(Icons.ac_unit, color: Colors.white, size: size);
    case 95:
    case 96:
    case 99:
      return Icon(Icons.thunderstorm,
          color: Colors.deepPurpleAccent, size: size);
    default:
      return Icon(Icons.help_outline, color: Colors.white, size: size);
  }
}
