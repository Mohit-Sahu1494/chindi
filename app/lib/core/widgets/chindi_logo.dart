import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ChindiLogo extends StatelessWidget {
  final double size;
  final bool showGlow;
  final BorderRadius? borderRadius;

  const ChindiLogo({
    super.key,
    this.size = 64.0,
    this.showGlow = true,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(size * 0.26);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: radius,
        border: Border.all(
          color: AppColors.hairlineActive,
          width: 1.2,
        ),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.28),
                  blurRadius: size * 0.35,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: size * 0.2,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          'assets/images/chindi_logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover, // Fills the entire app logo container without clipping or awkward borders
          errorBuilder: (context, error, stackTrace) {
            // High quality fallback vector emblem
            return Container(
              color: AppColors.surfaceElevated,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => AppColors.goldGradient.createShader(bounds),
                    child: Text(
                      '₹',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size * 0.48,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
