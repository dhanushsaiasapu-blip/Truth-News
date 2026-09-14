import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../routes/app_routes.dart';
import '../../services/bookmark_service.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const String _feedbackKey = 'user_feedback';

  int _selectedRating = 0;
  bool _ratingSubmitted = false;
  bool _feedbackSubmitted = false;
  final TextEditingController _feedbackController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }


  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final rating = prefs.getInt('app_rating') ?? 0;
    final ratingSubmitted = prefs.getBool('rating_submitted') ?? false;
    final feedbackSubmitted = prefs.getBool('feedback_submitted') ?? false;
    if (mounted) {
      setState(() {
        _selectedRating = rating;
        _ratingSubmitted = ratingSubmitted;
        _feedbackSubmitted = feedbackSubmitted;
      });
    }
  }

  Future<void> _submitRating(int rating) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('app_rating', rating);
    await prefs.setBool('rating_submitted', true);
    if (mounted) {
      setState(() {
        _selectedRating = rating;
        _ratingSubmitted = true;
      });
      if (rating >= 4) {
        _showRateOnStoreDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Thanks for your rating! We\'ll keep improving.',
              style: GoogleFonts.manrope(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF2D2D2D),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showRateOnStoreDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Loving Truth? ⭐',
          style: GoogleFonts.manrope(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'Rate us on Google Play to help others discover balanced news.',
          style: GoogleFonts.manrope(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Maybe later',
              style: GoogleFonts.manrope(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              launchUrl(Uri.parse('https://play.google.com/store/apps/details?id=com.dhanush.truth'));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Rate Now',
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitFeedback() async {
    final text = _feedbackController.text.trim();
    if (text.isEmpty) return;

    final subject = Uri.encodeComponent('App Feedback - Truth News');
    final body = Uri.encodeComponent(text);
    final emailUri = Uri.parse(
      'mailto:truthscrollablenews@gmail.com?subject=$subject&body=$body',
    );

    bool launched = false;
    try {
      launched = await launchUrl(emailUri);
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_feedbackKey, text);
    await prefs.setBool('feedback_submitted', true);

    if (mounted) {
      setState(() => _feedbackSubmitted = true);
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            launched
                ? 'Opening email to send feedback...'
                : 'Feedback saved! Thank you 🙏',
            style: GoogleFonts.manrope(color: Colors.white),
          ),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.black,
            expandedHeight: 120,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
              title: Text(
                'Profile',
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primary.withAlpha(40), Colors.black],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const SizedBox(height: 8),
                  _buildBookmarksSection(),
                  const SizedBox(height: 24),
                  _buildRateSection(),
                  const SizedBox(height: 24),
                  _buildFeedbackSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primary.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.manrope(fontSize: 12, color: Colors.white54),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookmarksSection() {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: BookmarkService.instance.bookmarks,
      builder: (context, bookmarks, _) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withAlpha(15)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => context.push(AppRoutes.bookmarksScreen),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.bookmark_rounded,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Bookmarks',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        bookmarks.isEmpty
                            ? 'No saved stories yet'
                            : '${bookmarks.length} saved ${bookmarks.length == 1 ? 'story' : 'stories'}',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white38,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRateSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Rate This App',
            'How are we doing? Your feedback matters',
            Icons.star_rounded,
          ),
          const SizedBox(height: 20),
          if (_ratingSubmitted) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.primary.withAlpha(60)),
              ),
              child: Row(
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thanks for rating us!',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: List.generate(5, (i) {
                            return Icon(
                              i < _selectedRating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: i < _selectedRating
                                  ? const Color(0xFFFFC107)
                                  : Colors.white30,
                              size: 20,
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('rating_submitted', false);
                      if (mounted) setState(() => _ratingSubmitted = false);
                    },
                    child: Text(
                      'Change',
                      style: GoogleFonts.manrope(
                        color: AppTheme.primary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Center(
              child: Column(
                children: [
                  Text(
                    _selectedRating == 0
                        ? 'Tap a star to rate'
                        : _selectedRating <= 2
                        ? 'We\'ll do better 💪'
                        : _selectedRating == 3
                        ? 'Thanks! We\'re improving 🙏'
                        : _selectedRating == 4
                        ? 'Great! We love that 😊'
                        : 'Amazing! You\'re the best! 🌟',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: Colors.white60,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final starIndex = i + 1;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedRating = starIndex),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: AnimatedScale(
                            scale: _selectedRating >= starIndex ? 1.2 : 1.0,
                            duration: const Duration(milliseconds: 150),
                            child: Icon(
                              _selectedRating >= starIndex
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: _selectedRating >= starIndex
                                  ? const Color(0xFFFFC107)
                                  : Colors.white30,
                              size: 40,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedRating > 0
                          ? () => _submitRating(_selectedRating)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        disabledBackgroundColor: Colors.white12,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Submit Rating',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _selectedRating > 0
                              ? Colors.white
                              : Colors.white38,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Send Feedback',
            'Help us make Truth better for everyone',
            Icons.chat_bubble_outline_rounded,
          ),
          const SizedBox(height: 20),
          if (_feedbackSubmitted) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A3A2A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.withAlpha(80)),
              ),
              child: Row(
                children: [
                  const Text('✅', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Feedback received!',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'We read every message. Thank you!',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('feedback_submitted', false);
                      _feedbackController.clear();
                      if (mounted) setState(() => _feedbackSubmitted = false);
                    },
                    child: Text(
                      'Send more',
                      style: GoogleFonts.manrope(
                        color: AppTheme.primary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withAlpha(20)),
              ),
              child: TextField(
                controller: _feedbackController,
                maxLines: 5,
                maxLength: 500,
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText:
                      'What do you love? What could be better? Any bugs to report?',
                  hintStyle: GoogleFonts.manrope(
                    color: Colors.white30,
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  counterStyle: GoogleFonts.manrope(
                    color: Colors.white30,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.email_outlined,
                        size: 13,
                        color: Colors.white38,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Sent to truthscrollablenews@gmail.com',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            color: Colors.white38,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _submitFeedback,
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: Text(
                    'Send',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
