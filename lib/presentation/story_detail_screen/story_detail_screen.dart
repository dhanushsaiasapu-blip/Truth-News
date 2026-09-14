import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/bookmark_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_image_widget.dart';
import './widgets/article_actions_widget.dart';
import './widgets/article_author_widget.dart';
import './widgets/blockquote_widget.dart';
import './widgets/outlet_coverage_widget.dart';

class StoryDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? storyData;

  const StoryDetailScreen({super.key, this.storyData});

  @override
  State<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends State<StoryDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _isBookmarked = false;
  bool _showOutletPanel = false;
  late AnimationController _panelController;
  late Animation<Offset> _panelSlide;

  late Map<String, dynamic> _story;

  @override
  void initState() {
    super.initState();
    final data = widget.storyData;
    _story = data == null ? <String, dynamic>{} : Map<String, dynamic>.from(data);
    if (_story.isNotEmpty) {
      _story['id'] = _story['id'] is String ? _story['id'] : '';
      _story['headline'] = _story['headline'] is String ? _story['headline'] : 'Untitled story';
      _story['neutralSummary'] = _story['neutralSummary'] is String ? _story['neutralSummary'] : '';
      _story['category'] = _story['category'] is String ? _story['category'] : 'News';
      _story['sourceName'] = _story['sourceName'] is String ? _story['sourceName'] : 'Unknown source';
      _story['publishedAgo'] = _story['publishedAgo'] is String ? _story['publishedAgo'] : 'Publication time unavailable';
      _story['articleUrl'] = _story['articleUrl'] is String ? _story['articleUrl'] : '';
      _story['imageUrl'] = _story['imageUrl'] is String ? _story['imageUrl'] : '';
      _story['semanticLabel'] = _story['semanticLabel'] is String ? _story['semanticLabel'] : _story['headline'];
      _story['summarySource'] = _story['summarySource'] == 'ai' ? 'ai' : 'source';
      _story['outlets'] = _story['outlets'] is List ? _story['outlets'] : <Map<String, String>>[];
      _story['outletCount'] = _story['outlets'].length;
    }

    _isBookmarked = BookmarkService.instance.isBookmarked(
      _story['id'] as String,
    );

    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _panelSlide = Tween<Offset>(begin: const Offset(1.0, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _panelController, curve: Curves.easeOutCubic),
        );
  }

  @override
  void dispose() {
    _panelController.dispose();
    super.dispose();
  }

  Future<void> _toggleBookmark() async {
    final nowBookmarked = await BookmarkService.instance.toggle(_story);
    if (mounted) setState(() => _isBookmarked = nowBookmarked);
  }

  Future<void> _shareStory() async {
    final headline = _story['headline'] as String? ?? 'Truth';
    final summary = _shortSummary;
    final link = _story['articleUrl'] as String;
    final text = [
      headline,
      summary,
      link,
      'Read every side of the story on Truth.',
    ].join('\n\n');
    await Share.share(text, subject: headline);
  }

  Future<void> _openOriginal() async {
    final url = _story['articleUrl'] as String;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open the original article.')),
        );
      }
    }
  }

  void _toggleOutletPanel() {
    setState(() => _showOutletPanel = !_showOutletPanel);
    if (_showOutletPanel) {
      _panelController.forward();
    } else {
      _panelController.reverse();
    }
  }

  /// Returns a ≤60-word summary
  String get _shortSummary {
    final text = _story['neutralSummary'] as String;
    final words = text.trim().split(RegExp(r'\s+'));
    if (words.length <= 60) return text;
    return '${words.take(60).join(' ')}…';
  }


  @override
  Widget build(BuildContext context) {
    if (_story.isEmpty || (_story['id'] as String).isEmpty || (_story['articleUrl'] as String).isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Story unavailable')),
        body: const Center(child: Text('This story is unavailable.')),
      );
    }
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final outlets = <Map<String, String>>[];
    final rawOutlets = _story['outlets'];
    if (rawOutlets is List) {
      for (final item in rawOutlets) {
        if (item is! Map) continue;
        final name = item['name'];
        final articleUrl = item['articleUrl'] ?? item['url'];
        if (name is! String || articleUrl is! String ||
            name.trim().isEmpty || articleUrl.trim().isEmpty) {
          continue;
        }
        final uri = Uri.tryParse(articleUrl.trim());
        if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
          continue;
        }
        outlets.add({
          'name': name.trim(),
          'lean': item['lean'] is String ? (item['lean'] as String).trim() : 'Unknown',
          'framing': item['framing'] is String ? (item['framing'] as String).trim() : '',
          'articleUrl': articleUrl.trim(),
        });
      }
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(theme),
                Expanded(
                  child: isTablet
                      ? _buildTabletLayout(theme, outlets)
                      : _buildPhoneLayout(theme, outlets),
                ),
              ],
            ),
          ),
          // Outlet panel overlay (phone only)
          if (!isTablet)
            SlideTransition(
              position: _panelSlide,
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.88,
                  height: double.infinity,
                  color: Colors.transparent,
                  child: SafeArea(
                    child: OutletCoverageWidget(
                      outlets: outlets,
                      outletCount: outlets.length,
                      onClose: _toggleOutletPanel,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: ArticleActionsWidget(
          isBookmarked: _isBookmarked,
          onBookmark: _toggleBookmark,
          onShare: _shareStory,
          onOpenOriginal: _openOriginal,
          onShowOutlets: _toggleOutletPanel,
          outletCount: outlets.length,
        ),
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
      color: theme.scaffoldBackgroundColor,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppTheme.headlineText,
            onPressed: () => context.pop(),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(26),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _story['category'] as String,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneLayout(ThemeData theme, List<Map<String, String>> outlets) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ArticleAuthorWidget(
            outletCount: outlets.length,
            publishedAgo: _story['publishedAgo'] as String,
            isAiSummary: _story['summarySource'] == 'ai',
          ),
          const SizedBox(height: 14),
          Text(
            _story['headline'] as String,
            style: theme.textTheme.headlineLarge?.copyWith(height: 1.3),
          ),
          const SizedBox(height: 14),
          // Hero image
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CustomImageWidget(
              imageUrl: _story['imageUrl'] as String,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              semanticLabel: _story['semanticLabel'] as String,
            ),
          ),
          const SizedBox(height: 12),
          // Summary (≤60 words) + Read More
          _buildSummarySection(theme),
          const SizedBox(height: 24),
          _buildSwipeHint(theme),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSummarySection(ThemeData theme) {
    final isAi = _story['summarySource'] == 'ai';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlockquoteWidget(summary: _shortSummary),
        const SizedBox(height: 12),
        Text(
          isAi
              ? 'AI-assisted summary based on retrieved source material.'
              : 'Summary from the retrieved source material.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        Text(
          'Open the original article below to read the complete reporting from ${_story['sourceName']}.',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildTabletLayout(
    ThemeData theme,
    List<Map<String, String>> outlets,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ArticleAuthorWidget(
                  outletCount: outlets.length,
                  publishedAgo: _story['publishedAgo'] as String,
                  isAiSummary: _story['summarySource'] == 'ai',
                ),
                const SizedBox(height: 14),
                Text(
                  _story['headline'] as String,
                  style: theme.textTheme.headlineLarge?.copyWith(height: 1.3),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CustomImageWidget(
                    imageUrl: _story['imageUrl'] as String,
                    width: double.infinity,
                    height: 240,
                    fit: BoxFit.cover,
                    semanticLabel: _story['semanticLabel'] as String,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSummarySection(theme),
              ],
            ),
          ),
        ),
        Container(
          width: 1,
          color: AppTheme.outlineLight,
          margin: const EdgeInsets.symmetric(vertical: 16),
        ),
        Expanded(
          flex: 4,
          child: OutletCoverageWidget(
            outlets: outlets,
            outletCount: outlets.length,
            onClose: null,
          ),
        ),
      ],
    );
  }

  Widget _buildSwipeHint(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withAlpha(51)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.swipe_right_alt_rounded,
            color: AppTheme.primary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tap "See ${_story['outletCount']} Outlets" below to see how each outlet framed this story',
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.primary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
