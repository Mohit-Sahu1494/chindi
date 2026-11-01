import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HairlineDivider extends StatelessWidget {
  final double indent;
  final double endIndent;
  final double height;
  final Color? color;

  const HairlineDivider({
    super.key,
    this.indent = 0.0,
    this.endIndent = 0.0,
    this.height = 1.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: height,
      thickness: 0.8,
      indent: indent,
      endIndent: endIndent,
      color: color ?? AppColors.hairline,
    );
  }
}
