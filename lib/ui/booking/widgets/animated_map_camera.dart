import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Wraps a flutter_map [MapController] with animated pan/zoom transitions, so the camera can
/// smoothly reframe (like turn-by-turn navigation) instead of jumping. flutter_map's own
/// `MapController.move()` is an instant, unanimated jump — this hand-builds the animation the
/// same way [PulsingLocationMarker] does (single reused `AnimationController`, no extra package).
class AnimatedMapCamera {
  AnimatedMapCamera({required TickerProvider vsync})
      : _controller = AnimationController(vsync: vsync, duration: const Duration(milliseconds: 600));

  final MapController mapController = MapController();
  final AnimationController _controller;
  VoidCallback? _activeTick;
  bool _ready = false;

  /// Call from `MapOptions.onMapReady` — camera calls before the map has rendered once throw.
  void onMapReady() => _ready = true;

  Future<void> animateTo(LatLng center, double zoom) async {
    if (!_ready) return;
    if (_activeTick != null) _controller.removeListener(_activeTick!);

    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    final start = mapController.camera;
    final centerAnimation = LatLngTween(begin: start.center, end: center).animate(curved);
    final zoomAnimation = Tween<double>(begin: start.zoom, end: zoom).animate(curved);

    void tick() => mapController.move(centerAnimation.value, zoomAnimation.value);
    _activeTick = tick;
    _controller.addListener(tick);
    try {
      await _controller.forward(from: 0);
    } finally {
      _controller.removeListener(tick);
      if (identical(_activeTick, tick)) _activeTick = null;
    }
  }

  /// Reframes the camera to keep every point in [points] comfortably visible — the "zoom in/out to
  /// keep both pins in view" behavior. A single point just pans to it at the current zoom.
  Future<void> animateFit(
    List<LatLng> points, {
    EdgeInsets padding = const EdgeInsets.all(60),
    double? maxZoom,
  }) async {
    if (!_ready || points.isEmpty) return;
    if (points.length == 1) {
      await animateTo(points.first, mapController.camera.zoom);
      return;
    }
    final target = CameraFit.coordinates(
      coordinates: points,
      padding: padding,
      maxZoom: maxZoom ?? double.infinity,
    ).fit(mapController.camera);
    await animateTo(target.center, target.zoom);
  }

  void dispose() {
    _controller.dispose();
    mapController.dispose();
  }
}
