import 'package:geolocator/geolocator.dart';

class LocationException implements Exception {
  final String message;
  const LocationException(this.message);

  @override
  String toString() => message;
}

class LocationService {
  /// Returns the device position, asking for permission when needed.
  Future<Position> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(
          'Location services are disabled. Please enable them or search for a city.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException(
          'Geolocation is not available, please enable it in your app settings or search for a city.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
          'Location permission is permanently denied. Please allow it in your device settings or search for a city.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }
}
