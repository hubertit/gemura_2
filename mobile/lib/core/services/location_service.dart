import 'package:geolocator/geolocator.dart';

class LocationService {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();
  
  LocationService._();

  /// Get current user location
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Check if location permissions are granted
  Future<bool> hasLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }

  /// Request location permissions
  Future<bool> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      return permission == LocationPermission.always || 
             permission == LocationPermission.whileInUse;
    } catch (e) {
      print('Error requesting location permission: $e');
      return false;
    }
  }

  /// Calculate distance between two coordinates in kilometers
  double calculateDistance(
    double lat1, 
    double lon1, 
    double lat2, 
    double lon2
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // Convert to km
  }

  /// Format distance for display
  String formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).round()}m';
    } else if (distanceInKm < 10) {
      return '${distanceInKm.toStringAsFixed(1)}km';
    } else {
      return '${distanceInKm.round()}km';
    }
  }

  /// Parse GPS coordinates from string format
  /// Expected format: "lat,lng" or "lat, lng"
  Map<String, double>? parseCoordinates(String? coordinateString) {
    if (coordinateString == null || coordinateString.isEmpty) {
      return null;
    }

    try {
      final parts = coordinateString.split(',');
      if (parts.length != 2) {
        return null;
      }

      final lat = double.parse(parts[0].trim());
      final lng = double.parse(parts[1].trim());

      return {'lat': lat, 'lng': lng};
    } catch (e) {
      print('Error parsing coordinates: $e');
      return null;
    }
  }

  /// Get distance from current location to target coordinates
  Future<String?> getDistanceFromCurrentLocation(
    String? targetCoordinates,
  ) async {
    if (targetCoordinates == null || targetCoordinates.isEmpty) {
      return null;
    }

    final currentLocation = await getCurrentLocation();
    if (currentLocation == null) {
      return null;
    }

    final targetCoords = parseCoordinates(targetCoordinates);
    if (targetCoords == null) {
      return null;
    }

    final distance = calculateDistance(
      currentLocation.latitude,
      currentLocation.longitude,
      targetCoords['lat']!,
      targetCoords['lng']!,
    );

    return formatDistance(distance);
  }
}
