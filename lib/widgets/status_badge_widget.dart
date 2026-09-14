import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class StatusBadgeWidget extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;

  const StatusBadgeWidget({
    super.key,
    required this.label,
    required this.color,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color : color.withAlpha(31),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: filled ? Colors.white : color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class LeanBadgeWidget extends StatelessWidget {
  final String lean;

  const LeanBadgeWidget({super.key, required this.lean});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.leanColor(lean);
    final label = AppTheme.leanShort(lean);
    return StatusBadgeWidget(label: label, color: color);
  }
}
