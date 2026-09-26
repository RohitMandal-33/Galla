import 'package:flutter/material.dart';

import '../../../core/theme/galla_theme.dart';

/// Shown while [settingsProvider] is still loading on a cold start.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GallaColors.canvas,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: GallaColors.brandSoft,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: GallaElevation.card,
                ),
                padding: const EdgeInsets.all(14),
                child: Image.asset(
                  'assets/images/galla_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.storefront_rounded,
                    size: 40,
                    color: GallaColors.brand,
                  ),
                ),
              ),
              const SizedBox(height: GallaSpacing.lg),
              Text('Galla', style: GallaType.numberXl),
              const SizedBox(height: GallaSpacing.xs),
              Text(
                'Your daily khata',
                style: GallaType.body.copyWith(color: GallaColors.muted),
              ),
              const SizedBox(height: GallaSpacing.xxl),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: GallaColors.brand,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
