import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/map_provider.dart';
import '../widgets/map/index.dart';

class ExploreMapWidget extends StatelessWidget {
  const ExploreMapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MapProvider(),
      child: const MapContainer(),
    );
  }
} 