import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import '../../config/mapbox_config.dart';

class MapViewWidget extends StatelessWidget {
  final void Function(MapboxMap) onMapCreated;
  final geolocator.Position? currentPosition;

  const MapViewWidget({
    super.key,
    required this.onMapCreated,
    this.currentPosition,
  });

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      key: const ValueKey('mapWidget'),
      cameraOptions: CameraOptions(
        center: currentPosition != null
            ? Point(coordinates: Position(currentPosition!.longitude, currentPosition!.latitude))
            : Point(coordinates: Position(78.9629, 20.5937)), // India center as fallback
        zoom: currentPosition != null ? 12.0 : 5.0,
        pitch: 0.0,
        bearing: 0.0,
      ),
      styleUri: MapboxConfig.customStyleUrl,
      onMapCreated: onMapCreated,
    );
  }
} 