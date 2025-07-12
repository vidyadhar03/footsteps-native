import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:permission_handler/permission_handler.dart';
import '../config/mapbox_config.dart';

enum MapState { loading, loaded, error }

class MapProvider extends ChangeNotifier {
  // Map instance
  MapboxMap? _mapboxMap;
  
  // Location data
  geolocator.Position? _currentPosition;
  bool _locationPermissionGranted = false;
  
  // UI state
  MapState _state = MapState.loading;
  String _errorMessage = '';
  
  // Getters
  MapboxMap? get mapboxMap => _mapboxMap;
  geolocator.Position? get currentPosition => _currentPosition;
  bool get locationPermissionGranted => _locationPermissionGranted;
  MapState get state => _state;
  String get errorMessage => _errorMessage;
  bool get isLoading => _state == MapState.loading;
  bool get isLoaded => _state == MapState.loaded;
  bool get hasError => _state == MapState.error;

  // Public methods
  Future<void> initializeMap() async {
    _setState(MapState.loading);
    
    try {
      await _checkLocationPermission();
      await _getCurrentLocation();
      _setState(MapState.loaded);
    } catch (e) {
      _setError('Error initializing map: ${e.toString()}');
    }
  }

  Future<void> onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    await _setupMapStyle();
    
    // Add user location marker if available
    if (_currentPosition != null) {
      await _addUserLocationMarker();
    }
  }

  Future<void> retryInitialization() async {
    _setState(MapState.loading);
    await initializeMap();
  }

  // Private methods
  void _setState(MapState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _setState(MapState.error);
  }

  Future<void> _checkLocationPermission() async {
    final status = await Permission.location.status;
    if (status.isGranted) {
      _locationPermissionGranted = true;
    } else if (status.isDenied) {
      final result = await Permission.location.request();
      _locationPermissionGranted = result.isGranted;
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!_locationPermissionGranted) return;

    try {
      final position = await geolocator.Geolocator.getCurrentPosition(
        desiredAccuracy: geolocator.LocationAccuracy.high,
      );
      _currentPosition = position;
      notifyListeners();
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _setupMapStyle() async {
    if (_mapboxMap == null) return;

    try {
      await _mapboxMap!.loadStyleURI(MapboxConfig.customStyleUrl);
      debugPrint('Map style loaded successfully');
    } catch (e) {
      debugPrint('Error loading map style: $e');
      try {
        await _mapboxMap!.loadStyleURI(MapboxConfig.defaultStyleUrl);
      } catch (fallbackError) {
        debugPrint('Error loading fallback style: $fallbackError');
      }
    }
  }

  Future<void> _addUserLocationMarker() async {
    if (_mapboxMap == null || _currentPosition == null) return;

    try {
      final userLocationGeoJson = '''
      {
        "type": "Feature",
        "properties": {"type": "user"},
        "geometry": {
          "type": "Point",
          "coordinates": [${_currentPosition!.longitude}, ${_currentPosition!.latitude}]
        }
      }
      ''';

      await _mapboxMap!.style.addSource(GeoJsonSource(
        id: 'user-location',
        data: userLocationGeoJson,
      ));

      await _mapboxMap!.style.addLayer(CircleLayer(
        id: 'user-location-marker',
        sourceId: 'user-location',
        circleRadius: 8.0,
        circleColor: const Color(0xFF2196F3).toARGB32(),
        circleStrokeWidth: 3.0,
        circleStrokeColor: Colors.white.toARGB32(),
      ));

      debugPrint('User location added successfully');
    } catch (e) {
      debugPrint('Error adding user location: $e');
    }
  }
} 