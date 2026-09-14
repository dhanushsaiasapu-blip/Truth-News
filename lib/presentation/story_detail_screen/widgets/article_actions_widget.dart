import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';

class ArticleActionsWidget extends StatelessWidget {
  final bool isBookmarked;
  final VoidCallback onBookmark;
  final VoidCallback onShare;
  final VoidCallback onOpenOriginal;
  final VoidCallback onShowOutlets;
  final int outletCount;

  const ArticleActionsWidget({
    super.key,
    required this.isBookmarked,
    required this.onBookmark,
    required this.onShare,
    required this.onOpenOriginal,
    required this.onShowOutlets,
    required this.outletCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: AppTheme.outlineLight, width: 1)),
      ),
      child: Row(
        children: [
          _ActionIcon(
            icon: isBookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            color: isBookmarked ? AppTheme.primary : AppTheme.mutedText,
            onTap: onBookmark,
          ),
          const SizedBox(width: 16),
          _ActionIcon(
            icon: Icons.share_rounded,
            color: AppTheme.mutedText,
            onTap: onShare,
          ),
          const SizedBox(width: 16),
          _ActionIcon(
            icon: Icons.open_in_new_rounded,
            color: AppTheme.mutedText,
            onTap: onOpenOriginal,
          ),
          const Spacer(),
          // Primary CTA — See outlets
          GestureDetector(
            onTap: onShowOutlets,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                'See $outletCount Outlets',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      splashColor: AppTheme.primary.withAlpha(26),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 22, color: color),
      ),
    );
  }
}
