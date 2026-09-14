import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../presentation/bookmarks_screen/bookmarks_screen.dart';
import '../presentation/news_feed_screen/news_feed_screen.dart';
import '../presentation/story_detail_screen/story_detail_screen.dart';
import '../presentation/terms_privacy_screen/terms_privacy_screen.dart';
import '../presentation/profile_screen/profile_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String storyDetailScreen = '/story-detail-screen';
  static const String termsPrivacyScreen = '/terms-privacy-screen';
  static const String profileScreen = '/profile-screen';
  static const String bookmarksScreen = '/bookmarks-screen';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.initial,
  routes: [
    GoRoute(
      path: AppRoutes.initial,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: NewsFeedScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.storyDetailScreen,
      pageBuilder: (context, state) {
        final extra = state.extra;
        final story = extra is Map ? Map<String, dynamic>.from(extra) : null;
        return CustomTransitionPage(
          key: state.pageKey,
          child: StoryDetailScreen(storyData: story),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1.0, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          transitionDuration: const Duration(milliseconds: 280),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.termsPrivacyScreen,
      pageBuilder: (context, state) {
        final value = state.extra;
        final extra = value is Map ? Map<String, dynamic>.from(value) : null;
        final showPrivacy = extra?['showPrivacy'] is bool ? extra!['showPrivacy'] as bool : false;
        return CustomTransitionPage(
          key: state.pageKey,
          child: TermsPrivacyScreen(showPrivacy: showPrivacy),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 1.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 280),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.profileScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ProfileScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(1.0, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 280),
      ),
    ),
    GoRoute(
      path: AppRoutes.bookmarksScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const BookmarksScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(1.0, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 280),
      ),
    ),
  ],
);
