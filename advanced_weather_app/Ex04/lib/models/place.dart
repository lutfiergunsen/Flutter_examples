class Place {
  final String name;
  final String region;
  final String country;
  final double latitude;
  final double longitude;

  const Place({
    required this.name,
    required this.region,
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  /// Parses one result of the Open-Meteo geocoding API.
  factory Place.fromOpenMeteo(Map<String, dynamic> json) {
    return Place(
      name: json['name'] as String? ?? '',
      region: json['admin1'] as String? ?? '',
      country: json['country'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  /// Parses a Nominatim reverse geocoding response.
  factory Place.fromNominatim(
      Map<String, dynamic> json, double latitude, double longitude) {
    final address = (json['address'] as Map<String, dynamic>?) ?? const {};
    final name = address['city'] ??
        address['town'] ??
        address['village'] ??
        address['municipality'] ??
        address['county'] ??
        'Current location';
    return Place(
      name: name as String,
      region: (address['state'] ??
          address['province'] ??
          address['region'] ??
          '') as String,
      country: (address['country'] ?? '') as String,
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// "Region, Country" without dangling commas when a part is missing.
  String get subtitle =>
      [region, country].where((part) => part.isNotEmpty).join(', ');
}
