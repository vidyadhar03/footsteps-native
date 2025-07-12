import 'package:flutter_dotenv/flutter_dotenv.dart';

class MapboxConfig {
  static String get accessToken {
    final token = dotenv.env['MAPBOX_ACCESS_TOKEN'];
    if (token == null || token.isEmpty) {
      throw Exception('MAPBOX_ACCESS_TOKEN not found in .env.local file');
    }
    return token;
  }

  // Default map style URL - you can change this to your custom style
  static String get defaultStyleUrl {
    return 'mapbox://styles/mapbox/streets-v12';
  }

  // Custom style URL - replace with your Mapbox Studio style URL
  static String get customStyleUrl {
    // Using satellite style with street labels for premium visual experience
    return 'mapbox://styles/mapbox/satellite-streets-v12';
  }

  // Map configuration constants
  static const double defaultZoom = 10.0;
  static const double maxZoom = 20.0;
  static const double minZoom = 2.0;
  
  // 3D terrain and building settings
  static const bool enable3DTerrain = true;
  static const bool enableBuildingExtrusions = true;
  static const double buildingExtrusionOpacity = 0.8;
  
  // Clustering settings
  static const bool enableClustering = true;
  static const int clusterRadius = 50;
  static const int clusterMaxZoom = 14;
  
  // Performance settings
  static const bool enableTileCaching = true;
  static const int maxCacheSize = 50; // MB
} 