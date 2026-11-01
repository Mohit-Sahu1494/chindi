import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MonogramAvatar extends StatelessWidget {
  final String name;
  final double size;
  final double borderWidth;
  final TextStyle? textStyle;

  const MonogramAvatar({
    super.key,
    required this.name,
    this.size = 36.0,
    this.borderWidth = 1.0,
    this.textStyle,
  });

  String _getInitials(String rawName) {
    final clean = rawName.trim();
    if (clean.isEmpty) return '?';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return clean.substring(0, clean.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(name);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceElevated,
        border: Border.all(
          color: AppColors.hairlineActive,
          width: borderWidth,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: textStyle ??
              TextStyle(
                color: AppColors.gold,
                fontSize: size * 0.38,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
        ),
      ),
    );
  }
}
