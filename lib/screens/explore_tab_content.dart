import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'explore_map_widget.dart';

class ExploreTabContent extends StatelessWidget {
  const ExploreTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: const Scaffold(
        extendBodyBehindAppBar: true,
        body: ExploreMapWidget(),
      ),
    );
  }
} 