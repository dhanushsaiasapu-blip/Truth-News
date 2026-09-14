import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../news_feed_screen.dart';

class NewsListItemWidget extends StatefulWidget {
  final StoryModel story;
  final VoidCallback onTap;
  final int animationIndex;

  const NewsListItemWidget({
    super.key,
    required this.story,
    required this.onTap,
    required this.animationIndex,
  });

  @override
  State<NewsListItemWidget> createState() => _NewsListItemWidgetState();
}

class _NewsListItemWidgetState extends State<NewsListItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    final delay = (widget.animationIndex * 60).clamp(0, 400);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppTheme.primary.withAlpha(20),
          highlightColor: AppTheme.primary.withAlpha(10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.outlineLight, width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CustomImageWidget(
                    imageUrl: widget.story.imageUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    semanticLabel: widget.story.semanticLabel,
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.story.category,
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: AppTheme.mutedText,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.story.outletCount} outlets',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.mutedText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.story.headline,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.headlineText,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 11,
                            color: AppTheme.mutedText,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            widget.story.publishedAgo,
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              color: AppTheme.mutedText,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.swipe_right_alt_rounded,
                            size: 14,
                            color: AppTheme.primary.withAlpha(179),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Swipe for bias',
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primary.withAlpha(179),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
