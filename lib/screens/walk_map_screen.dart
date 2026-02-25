import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../controllers/walk_controller.dart';
import '../core/theme/app_theme.dart';
import '../widgets/nebula_background.dart';

class WalkMapScreen extends StatefulWidget {
  const WalkMapScreen({super.key, required this.controller});

  final WalkController controller;

  @override
  State<WalkMapScreen> createState() => _WalkMapScreenState();
}

class _WalkMapScreenState extends State<WalkMapScreen> {
  static const String _tileTemplate =
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
  static const List<String> _tileSubdomains = <String>['a', 'b', 'c', 'd'];
  static const double _defaultZoom = 16;

  final MapController _mapController = MapController();
  final List<LatLng> _trail = <LatLng>[];
  StreamSubscription<Position>? _positionSub;
  LatLng? _currentPoint;
  Position? _latestPosition;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
  }

  Future<void> _startLocationTracking() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _error = 'Enable location services to view walk map.';
      });
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        _error = 'Location permission denied.';
      });
      return;
    }

    final current = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
      ),
    );
    _pushPosition(current, moveCamera: true);

    _positionSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 2,
          ),
        ).listen(
          (position) {
            _pushPosition(position, moveCamera: true);
          },
          onError: (_) {
            if (!mounted) {
              return;
            }
            setState(() {
              _error = 'Unable to read live location updates.';
            });
          },
        );
  }

  void _pushPosition(Position position, {required bool moveCamera}) {
    if (!_shouldAcceptPosition(position)) {
      return;
    }
    final point = LatLng(position.latitude, position.longitude);
    if (!mounted) {
      return;
    }
    setState(() {
      _latestPosition = position;
      _currentPoint = point;
      if (_trail.isEmpty || _distanceInMeters(_trail.last, point) > 1.2) {
        _trail.add(point);
      }
    });
    if (moveCamera) {
      _mapController.move(point, _defaultZoom);
    }
  }

  bool _shouldAcceptPosition(Position position) {
    if (position.accuracy > 60) {
      return false;
    }
    if (_latestPosition == null) {
      return true;
    }

    final previous = LatLng(
      _latestPosition!.latitude,
      _latestPosition!.longitude,
    );
    final current = LatLng(position.latitude, position.longitude);
    final distance = _distanceInMeters(previous, current);
    final dtSeconds =
        position.timestamp
            .difference(_latestPosition!.timestamp)
            .inMilliseconds /
        1000.0;
    if (dtSeconds <= 0) {
      return true;
    }

    final speedMps = distance / dtSeconds;
    // Ignore GPS jumps that imply unrealistic walking speed.
    return speedMps <= 8.0;
  }

  double _distanceInMeters(LatLng a, LatLng b) {
    const distance = Distance();
    return distance.as(LengthUnit.Meter, a, b);
  }

  Future<void> _stopWalkAndExit() async {
    if (widget.controller.stats.isTracking) {
      await widget.controller.stopTracking();
    }
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final startPoint = _currentPoint ?? const LatLng(37.7749, -122.4194);
    return Scaffold(
      body: NebulaBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    Expanded(
                      child: AnimatedBuilder(
                        animation: widget.controller,
                        builder: (context, _) {
                          final stats = widget.controller.stats;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Walk Map',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                'Live steps: ${stats.liveSessionSteps}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _stopWalkAndExit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Stop'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: startPoint,
                            initialZoom: _defaultZoom,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: _tileTemplate,
                              subdomains: _tileSubdomains,
                              retinaMode: RetinaMode.isHighDensity(context),
                              userAgentPackageName: 'com.example.rush2earn',
                            ),
                            if (_trail.length >= 2)
                              PolylineLayer(
                                polylines: [
                                  Polyline(
                                    points: _trail,
                                    strokeWidth: 10,
                                    color: AppTheme.primary.withValues(
                                      alpha: 0.24,
                                    ),
                                  ),
                                  Polyline(
                                    points: _trail,
                                    strokeWidth: 5,
                                    color: AppTheme.primary,
                                  ),
                                ],
                              ),
                            if (_currentPoint != null)
                              CircleLayer(
                                circles: [
                                  CircleMarker(
                                    point: _currentPoint!,
                                    radius: 20,
                                    color: AppTheme.accent.withValues(
                                      alpha: 0.22,
                                    ),
                                  ),
                                ],
                              ),
                            if (_currentPoint != null)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    width: 18,
                                    height: 18,
                                    point: _currentPoint!,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppTheme.accent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.accent.withValues(
                                              alpha: 0.6,
                                            ),
                                            blurRadius: 12,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        Positioned(
                          right: 10,
                          top: 10,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              child: Text(
                                _latestPosition == null
                                    ? 'GPS: acquiring'
                                    : 'GPS ±${_latestPosition!.accuracy.toStringAsFixed(1)}m',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ),
                        ),
                        if (_error != null)
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 12,
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Text(
                                  _error!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentPoint != null) {
            _mapController.move(_currentPoint!, _defaultZoom);
          }
        },
        child: const Icon(Icons.my_location_rounded),
      ),
    );
  }
}
