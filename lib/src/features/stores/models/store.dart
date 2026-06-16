/// A supermarket near the user — either a curated store or an OSM POI.
class NearbyStore {
  final String? id; // curated store uuid (null for OSM-only)
  final int? osmId;
  final String name;
  final String? brand;
  final double lat;
  final double lng;
  final double distanceKm;
  final String source; // "curated" | "osm"
  final String? logoUrl;
  final bool hasPromotions;

  const NearbyStore({
    this.id,
    this.osmId,
    required this.name,
    this.brand,
    required this.lat,
    required this.lng,
    required this.distanceKm,
    required this.source,
    this.logoUrl,
    required this.hasPromotions,
  });

  bool get isCurated => source == 'curated';

  factory NearbyStore.fromJson(Map<String, dynamic> j) => NearbyStore(
        id: j['id']?.toString(),
        osmId: (j['osm_id'] as num?)?.toInt(),
        name: j['name']?.toString() ?? 'Supermarket',
        brand: j['brand']?.toString(),
        lat: (j['lat'] as num?)?.toDouble() ?? 0,
        lng: (j['lng'] as num?)?.toDouble() ?? 0,
        distanceKm: (j['distance_km'] as num?)?.toDouble() ?? 0,
        source: j['source']?.toString() ?? 'osm',
        logoUrl: j['logo_url']?.toString(),
        hasPromotions: j['has_promotions'] == true,
      );
}

/// A promotional price for a product at a store.
class Promotion {
  final String id;
  final String productName;
  final String? brand;
  final double? originalPrice;
  final double discountedPrice;
  final double? discountPct;
  final String? unit;
  final DateTime? validUntil;

  const Promotion({
    required this.id,
    required this.productName,
    this.brand,
    this.originalPrice,
    required this.discountedPrice,
    this.discountPct,
    this.unit,
    this.validUntil,
  });

  factory Promotion.fromJson(Map<String, dynamic> j) => Promotion(
        id: j['id']?.toString() ?? '',
        productName: j['product_name']?.toString() ?? '',
        brand: j['brand']?.toString(),
        originalPrice: (j['original_price'] as num?)?.toDouble(),
        discountedPrice: (j['discounted_price'] as num?)?.toDouble() ?? 0,
        discountPct: (j['discount_pct'] as num?)?.toDouble(),
        unit: j['unit']?.toString(),
        validUntil: j['valid_until'] != null
            ? DateTime.tryParse(j['valid_until'].toString())
            : null,
      );
}
