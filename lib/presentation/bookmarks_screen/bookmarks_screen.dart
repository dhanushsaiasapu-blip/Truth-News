import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';
import '../../services/bookmark_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state_widget.dart';
import '../news_feed_screen/news_feed_screen.dart' show StoryModel;
import '../news_feed_screen/widgets/news_list_item_widget.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.headlineText,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'My Bookmarks',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.headlineText,
          ),
        ),
      ),
      body: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: BookmarkService.instance.bookmarks,
        builder: (context, bookmarks, _) {
          if (bookmarks.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.bookmark_border_rounded,
              title: 'No bookmarks yet',
              subtitle: 'Tap the bookmark icon on a story to save it here.',
            );
          }
          final stories = <StoryModel>[];
          for (final bookmark in bookmarks) {
            try {
              stories.add(StoryModel.fromMap(bookmark));
            } on FormatException {
              // Ignore stale or malformed local bookmark records.
            }
          }
          if (stories.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.bookmark_border_rounded,
              title: 'No valid bookmarks',
              subtitle: 'Saved story data is unavailable. New stories can be saved from the feed.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: stories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final story = stories[index];
              return Dismissible(
                key: ValueKey(story.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.error,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.white,
                  ),
                ),
                onDismissed: (_) =>
                    BookmarkService.instance.remove(story.id),
                child: NewsListItemWidget(
                  story: story,
                  animationIndex: index,
                  onTap: () => context.push(
                    AppRoutes.storyDetailScreen,
                    extra: story.toMap(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
