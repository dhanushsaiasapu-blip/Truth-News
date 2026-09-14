import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';

class ArticleAuthorWidget extends StatelessWidget {
  final int outletCount;
  final String publishedAgo;
  final bool isAiSummary;

  const ArticleAuthorWidget({
    super.key,
    required this.outletCount,
    required this.publishedAgo,
    this.isAiSummary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Stacked outlet avatars
        SizedBox(
          width: outletCount >= 3 ? 64 : outletCount * 24.0,
          height: 32,
          child: Stack(
            children: List.generate(
              outletCount.clamp(0, 3),
              (i) => Positioned(
                left: i * 20.0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: [
                      AppTheme.primary,
                      AppTheme.leanCenterLeft,
                      AppTheme.leanRight,
                    ][i % 3].withAlpha(38),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.newspaper_rounded,
                      size: 12,
                      color: [
                        AppTheme.primary,
                        AppTheme.leanCenterLeft,
                        AppTheme.leanRight,
                      ][i % 3],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aggregated from $outletCount outlets',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.headlineText,
                ),
              ),
              Text(
                publishedAgo,
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.mutedText,
                ),
              ),
            ],
          ),
        ),
        // Source-first label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.secondary.withAlpha(26),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.secondary.withAlpha(51)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 12,
                color: AppTheme.secondary,
              ),
              const SizedBox(width: 4),
              Text(
                isAiSummary ? 'AI-assisted' : 'Source summary',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.secondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
