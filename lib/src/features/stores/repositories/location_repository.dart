import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// A simple lat/lng pair (decoupled from any map SDK type).
class GeoPoint {
  final double lat;
  final double lng;
  const GeoPoint(this.lat, this.lng);
}

/// Wraps device geolocation + permission handling.
class LocationRepository {
  /// Returns the user's current position, or null if location is unavailable
  /// or permission was denied.
  Future<GeoPoint?> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final pos = await Geolocator.getCurrentPosition();
    return GeoPoint(pos.latitude, pos.longitude);
  }
}

final locationRepositoryProvider =
    Provider<LocationRepository>((ref) => LocationRepository());

/// Resolves the current device position (null when unavailable/denied).
final currentPositionProvider = FutureProvider<GeoPoint?>((ref) async {
  return ref.watch(locationRepositoryProvider).currentPosition();
});
