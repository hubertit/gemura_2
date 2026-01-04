import 'dart:math';

class DistanceUtils {
  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in kilometers
  static double calculateDistance(
    double lat1, 
    double lon1, 
    double lat2, 
    double lon2
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    // Convert degrees to radians
    double lat1Rad = lat1 * pi / 180;
    double lon1Rad = lon1 * pi / 180;
    double lat2Rad = lat2 * pi / 180;
    double lon2Rad = lon2 * pi / 180;

    // Calculate differences
    double deltaLat = lat2Rad - lat1Rad;
    double deltaLon = lon2Rad - lon1Rad;

    // Haversine formula
    double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLon / 2) * sin(deltaLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Format distance for display
  static String formatDistance(double distanceInKm) {
    if (distanceInKm < 0.1) {
      return '${(distanceInKm * 1000).round()}m';
    } else if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).round()}m';
    } else if (distanceInKm < 10) {
      return '${distanceInKm.toStringAsFixed(1)}km';
    } else {
      return '${distanceInKm.round()}km';
    }
  }

  /// Parse GPS coordinates from string format
  /// Expected format: "lat,lng" or "lat, lng"
  static Map<String, double>? parseCoordinates(String? coordinateString) {
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

      // Validate coordinates
      if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
        return null;
      }

      return {'lat': lat, 'lng': lng};
    } catch (e) {
      print('Error parsing coordinates: $e');
      return null;
    }
  }

  /// Get distance with direction indicator
  static String getDistanceWithDirection(
    double userLat,
    double userLng,
    double targetLat,
    double targetLng,
  ) {
    final distance = calculateDistance(userLat, userLng, targetLat, targetLng);
    final direction = getDirection(userLat, userLng, targetLat, targetLng);
    
    return '${formatDistance(distance)} $direction';
  }

  /// Get cardinal direction from user to target
  static String getDirection(
    double userLat,
    double userLng,
    double targetLat,
    double targetLng,
  ) {
    final deltaLat = targetLat - userLat;
    final deltaLng = targetLng - userLng;
    
    final angle = atan2(deltaLng, deltaLat) * 180 / pi;
    
    if (angle >= -22.5 && angle < 22.5) return 'N';
    if (angle >= 22.5 && angle < 67.5) return 'NE';
    if (angle >= 67.5 && angle < 112.5) return 'E';
    if (angle >= 112.5 && angle < 157.5) return 'SE';
    if (angle >= 157.5 || angle < -157.5) return 'S';
    if (angle >= -157.5 && angle < -112.5) return 'SW';
    if (angle >= -112.5 && angle < -67.5) return 'W';
    if (angle >= -67.5 && angle < -22.5) return 'NW';
    
    return '';
  }
}
