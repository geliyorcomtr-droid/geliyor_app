import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/customer_location.dart';
import 'package:latlong2/latlong.dart';

class _MapTiles extends StatelessWidget {
  const _MapTiles();

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      fallbackUrl: 'https://tile.openstreetmap.de/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.geliyor.app',
      retinaMode: false,
      maxZoom: 19,
    );
  }
}

/// Kayıtlı konumu haritada gösterir. Dokununca işaret taşınır.
class LocationPickMap extends StatefulWidget {
  const LocationPickMap({
    super.key,
    this.latitude,
    this.longitude,
    this.interactive = true,
    this.onPicked,
  });

  final double? latitude;
  final double? longitude;
  final bool interactive;
  final void Function(double latitude, double longitude)? onPicked;

  @override
  State<LocationPickMap> createState() => _LocationPickMapState();
}

class _LocationPickMapState extends State<LocationPickMap> {
  final MapController _mapController = MapController();
  bool _ready = false;

  static const _fallback = LatLng(41.015137, 28.979530);

  LatLng get _center {
    final latitude = widget.latitude;
    final longitude = widget.longitude;
    if (latitude == null || longitude == null) return _fallback;
    return LatLng(latitude, longitude);
  }

  bool get _hasPoint => widget.latitude != null && widget.longitude != null;

  @override
  void didUpdateWidget(LocationPickMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_ready || !_hasPoint) return;
    if (oldWidget.latitude == widget.latitude &&
        oldWidget.longitude == widget.longitude) {
      return;
    }
    _mapController.move(_center, 16);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final map = FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _center,
        initialZoom: _hasPoint ? 16 : 11,
        onTap: widget.interactive
            ? (_, point) => widget.onPicked?.call(
                  point.latitude,
                  point.longitude,
                )
            : null,
        onMapReady: () {
          _ready = true;
          if (_hasPoint) _mapController.move(_center, 16);
        },
      ),
      children: [
        const _MapTiles(),
        if (_hasPoint)
          MarkerLayer(
            markers: [
              Marker(
                point: _center,
                width: 44,
                height: 44,
                alignment: Alignment.bottomCenter,
                child: const Icon(
                  Icons.location_on,
                  color: AppColors.primary,
                  size: 44,
                  shadows: [
                    Shadow(
                      color: Color(0x66000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.interactive) map else IgnorePointer(child: map),
          if (widget.interactive && _hasPoint)
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => CustomerLocation.open(
                      widget.latitude,
                      widget.longitude,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Text(
                        'Google Haritalar',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (widget.interactive)
            const Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.all(4),
              child: Text(
                '© OpenStreetMap',
                style: TextStyle(
                  color: AppColors.subText,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (!_hasPoint)
            const Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text(
                      'Haritaya dokunup işaretleyin',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Liste kutusunda harita. İşaret kutunun ortasında durur.
class LocationMapPreview extends StatelessWidget {
  const LocationMapPreview({
    super.key,
    this.latitude,
    this.longitude,
  });

  final double? latitude;
  final double? longitude;

  @override
  Widget build(BuildContext context) {
    if (!CustomerLocation.isValid(latitude, longitude)) {
      return const ColoredBox(
        color: AppColors.surface,
        child: Center(
          child: Icon(Icons.map_outlined, color: AppColors.primary, size: 22),
        ),
      );
    }
    const zoom = 15;
    const tile = 256.0;
    final n = 1 << zoom;
    final xFloat = (longitude! + 180) / 360 * n;
    final latRad = latitude! * math.pi / 180;
    final yFloat =
        (1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) /
        2 *
        n;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : tile;
          final height = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : 72.0;
          final originLeft = width / 2 - xFloat * tile;
          final originTop = height / 2 - yFloat * tile;
          final startX = ((-originLeft) / tile).floor().clamp(0, n - 1);
          final endX = ((width - originLeft) / tile).floor().clamp(0, n - 1);
          final startY = ((-originTop) / tile).floor().clamp(0, n - 1);
          final endY = ((height - originTop) / tile).floor().clamp(0, n - 1);
          return ColoredBox(
            color: AppColors.surface,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
              children: [
                for (var ty = startY; ty <= endY; ty++)
                  for (var tx = startX; tx <= endX; tx++)
                    Positioned(
                      left: originLeft + tx * tile,
                      top: originTop + ty * tile,
                      width: tile,
                      height: tile,
                      child: Image.network(
                        'https://tile.openstreetmap.org/$zoom/$tx/$ty.png',
                        width: tile,
                        height: tile,
                        fit: BoxFit.fill,
                        gaplessPlayback: true,
                        headers: const {
                          'User-Agent': 'geliyor.tr (com.geliyor.app)',
                        },
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                const Center(
                  child: Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
