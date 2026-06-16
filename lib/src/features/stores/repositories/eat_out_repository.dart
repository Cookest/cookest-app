import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

/// A nearby restaurant/café returned from the OSM-backed eat-out endpoint.
class EatOutPlace {
  final String name;
  final double lat;
  final double lng;
  final String? amenity;
  final String? cuisine;
  final String? address;

  EatOutPlace({
    required this.name,
    required this.lat,
    required this.lng,
    this.amenity,
    this.cuisine,
    this.address,
  });

  factory EatOutPlace.fromJson(Map<String, dynamic> json) => EatOutPlace(
        name: json['name']?.toString() ?? '',
        lat: (json['lat'] as num?)?.toDouble() ?? 0,
        lng: (json['lng'] as num?)?.toDouble() ?? 0,
        amenity: json['amenity']?.toString(),
        cuisine: json['cuisine']?.toString(),
        address: json['address']?.toString(),
      );
}

class EatOutRepository {
  final Dio _dio;
  EatOutRepository(this._dio);

  Future<List<EatOutPlace>> nearby(double lat, double lng,
      {int radius = 1500}) async {
    final response = await _dio.get('/api/eat-out/nearby', queryParameters: {
      'lat': lat,
      'lng': lng,
      'radius': radius,
    });
    final places = (response.data['places'] as List? ?? []);
    return places
        .map((p) => EatOutPlace.fromJson(p as Map<String, dynamic>))
        .toList();
  }
}

final eatOutRepositoryProvider = Provider<EatOutRepository>((ref) {
  return EatOutRepository(ref.watch(dioProvider));
});
