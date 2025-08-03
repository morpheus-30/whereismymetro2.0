import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

class Station {
  final String name;
  final String line;
  final double latitude;
  final double longitude;

  Station(this.name, this.line, this.latitude, this.longitude);
}

class MetroDataService {
  Future<List<Station>> loadStations() async {
    try {
      final String csvData = await rootBundle.loadString(
        'assets/DELHI_METRO_DATA.csv',
      );
      final lines = csvData.trim().split('\n');
      final stations = <Station>[];

      for (int i = 1; i < lines.length; i++) {
        final parts = lines[i].split(',');
        if (parts.length >= 4) {
          final name = parts[0].trim();
          final line = parts[1].trim();
          final lat = double.tryParse(parts[2].trim());
          final lng = double.tryParse(parts[3].trim());
          if (lat != null && lng != null) {
            stations.add(Station(name, line, lat, lng));
          }
        }
      }

      return stations;
    } catch (e) {
      print('Error reading metro data: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getNearestStation(
    double userLat,
    double userLng,
  ) async {
    final stations = await loadStations();

    Station? nearest;
    double minDistance = double.infinity;

    for (final station in stations) {
      final distance = _haversineDistance(
        userLat,
        userLng,
        station.latitude,
        station.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
        nearest = station;
      }
    }

    if (nearest != null) {
      return {'station': nearest, 'distance_km': minDistance};
    } else {
      return {};
    }
  }

  double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371; // Earth's radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double deg) => deg * pi / 180;
}
