import 'package:flutter/material.dart';

class MapLoadingWidget extends StatelessWidget {
  const MapLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF009688).withValues(alpha: 0.1),
            const Color(0xFF00695C).withValues(alpha: 0.1),
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF009688)),
            ),
            SizedBox(height: 24),
            Text(
              'Loading map...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF00695C),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 