import 'package:cookest_ui/cookest_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../../../core/theme/app_colors.dart';
import '../models/store.dart';
import '../repositories/location_repository.dart';
import '../repositories/stores_repository.dart';

/// OpenFreeMap vector style — clean, Apple-Maps-like, and key-free.
const _mapStyle = 'https://tiles.openfreemap.org/styles/bright';

class StoresMapScreen extends ConsumerStatefulWidget {
  const StoresMapScreen({super.key});

  @override
  ConsumerState<StoresMapScreen> createState() => _StoresMapScreenState();
}

class _StoresMapScreenState extends ConsumerState<StoresMapScreen> {
  MapLibreMapController? _controller;
  bool _styleLoaded = false;
  List<NearbyStore>? _markedStores;

  Future<void> _syncMarkers(List<NearbyStore> stores) async {
    final c = _controller;
    if (c == null || !_styleLoaded || identical(_markedStores, stores)) return;
    _markedStores = stores;
    await c.clearCircles();
    for (final s in stores) {
      await c.addCircle(CircleOptions(
        geometry: LatLng(s.lat, s.lng),
        circleRadius: 7,
        circleColor: s.isCurated ? '#EC4899' : '#64748B',
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 2,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final positionAsync = ref.watch(currentPositionProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Stores near you')),
      body: positionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            _LocationError(onRetry: () => ref.invalidate(currentPositionProvider)),
        data: (pos) {
          if (pos == null) {
            return _LocationError(
                onRetry: () => ref.invalidate(currentPositionProvider));
          }
          final storesAsync = ref.watch(nearbyStoresProvider((pos.lat, pos.lng)));
          // Push markers once both the map style and the data are ready.
          storesAsync.whenData((stores) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _syncMarkers(stores));
          });
          return Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.42,
                child: MapLibreMap(
                  styleString: _mapStyle,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(pos.lat, pos.lng),
                    zoom: 13,
                  ),
                  myLocationEnabled: true,
                  onMapCreated: (c) => _controller = c,
                  onStyleLoadedCallback: () {
                    _styleLoaded = true;
                    storesAsync.whenData(_syncMarkers);
                  },
                ),
              ),
              Expanded(child: _StoreList(stores: storesAsync)),
            ],
          );
        },
      ),
    );
  }
}

class _StoreList extends StatelessWidget {
  final AsyncValue<List<NearbyStore>> stores;
  const _StoreList({required this.stores});

  @override
  Widget build(BuildContext context) {
    return stores.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: Text('Could not load stores',
            style: TextStyle(color: context.appMuted)),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Text('No supermarkets found nearby',
                style: TextStyle(color: context.appMuted)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) => _StoreTile(store: list[i]),
        );
      },
    );
  }
}

class _StoreTile extends StatelessWidget {
  final NearbyStore store;
  const _StoreTile({required this.store});

  @override
  Widget build(BuildContext context) {
    final tappable = store.isCurated && store.id != null;
    return Material(
      color: context.appSurface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: tappable ? () => context.push('/stores/${store.id}') : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                store.isCurated ? LucideIcons.store : LucideIcons.mapPin,
                color: store.isCurated
                    ? CookestTokens.colorPrimaryDEFAULT
                    : context.appMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(store.name,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: context.appHeading)),
                    Text(
                      '${store.distanceKm.toStringAsFixed(1)} km'
                      '${store.brand != null ? ' · ${store.brand}' : ''}',
                      style: TextStyle(fontSize: 12, color: context.appMuted),
                    ),
                  ],
                ),
              ),
              if (store.hasPromotions)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: CookestTokens.colorPrimaryDEFAULT
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Deals',
                      style: TextStyle(
                          fontSize: 11,
                          color: CookestTokens.colorPrimaryDEFAULT,
                          fontWeight: FontWeight.w600)),
                ),
              if (tappable)
                Icon(LucideIcons.chevronRight,
                    size: 18, color: context.appMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationError extends StatelessWidget {
  final VoidCallback onRetry;
  const _LocationError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.mapPinOff, size: 40, color: context.appMuted),
            const SizedBox(height: 12),
            Text('Location unavailable',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: context.appHeading)),
            const SizedBox(height: 4),
            Text('Enable location to see supermarkets near you.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.appMuted)),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
