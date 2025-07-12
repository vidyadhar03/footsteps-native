import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/map_provider.dart';
import 'map_loading_widget.dart';
import 'map_error_widget.dart';
import 'map_view_widget.dart';

class MapContainer extends StatefulWidget {
  const MapContainer({super.key});

  @override
  State<MapContainer> createState() => _MapContainerState();
}

class _MapContainerState extends State<MapContainer> {
  @override
  void initState() {
    super.initState();
    // Initialize the map when the widget is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MapProvider>().initializeMap();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapProvider>(
      builder: (context, mapProvider, child) {
        if (mapProvider.isLoading) {
          return const MapLoadingWidget();
        }
        
        if (mapProvider.hasError) {
          return MapErrorWidget(
            errorMessage: mapProvider.errorMessage,
            onRetry: () => mapProvider.retryInitialization(),
          );
        }
        
        return MapViewWidget(
          onMapCreated: mapProvider.onMapCreated,
          currentPosition: mapProvider.currentPosition,
        );
      },
    );
  }
} 