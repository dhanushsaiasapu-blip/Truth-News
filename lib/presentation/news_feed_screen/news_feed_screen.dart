import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';
import '../../services/live_news_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_image_widget.dart';
import '../../widgets/empty_state_widget.dart';

class StoryModel {
  final String id;
  final String headline;
  final String neutralSummary;
  final String summarySource;
  final String category;
  final int outletCount;
  final String publishedAgo;
  final String publishedAt;
  final String sourceName;
  final String articleUrl;
  final String imageUrl;
  final String semanticLabel;
  final List<Map<String, String>> outlets;
  final bool isBreaking;

  const StoryModel({
    required this.id,
    required this.headline,
    required this.neutralSummary,
    required this.summarySource,
    required this.category,
    required this.outletCount,
    required this.publishedAgo,
    required this.publishedAt,
    required this.sourceName,
    required this.articleUrl,
    required this.imageUrl,
    required this.semanticLabel,
    required this.outlets,
    required this.isBreaking,
  });

  factory StoryModel.fromMap(Map<String, dynamic> map) {
    final id = _requiredString(map, 'id');
    final headline = _requiredString(map, 'headline');
    final articleUrl = _requiredUrl(map, 'articleUrl');
    final category = _optionalString(map['category']) ?? 'World';
    final summary = _optionalString(map['neutralSummary']) ?? headline;
    final summarySource = map['summarySource'] == 'ai' ? 'ai' : 'source';
    final sourceName = _optionalString(map['sourceName']) ?? 'Unknown source';
    final imageUrl = _optionalString(map['imageUrl']) ?? '';
    final semanticLabel = _optionalString(map['semanticLabel']) ?? headline;
    final publishedAt = _optionalString(map['publishedAt']) ?? '';
    final publishedAgo =
        _optionalString(map['publishedAgo']) ?? 'Publication time unavailable';
    final outlets = _parseOutlets(map['outlets']);

    return StoryModel(
      id: id,
      headline: headline,
      neutralSummary: summary,
      summarySource: summarySource,
      category: category,
      outletCount: outlets.isEmpty
          ? _safeInt(map['outletCount'], 1)
          : outlets.length,
      publishedAgo: publishedAgo,
      publishedAt: publishedAt,
      sourceName: sourceName,
      articleUrl: articleUrl,
      imageUrl: imageUrl,
      semanticLabel: semanticLabel,
      outlets: outlets,
      isBreaking: map['isBreaking'] is bool ? map['isBreaking'] as bool : false,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'headline': headline,
        'neutralSummary': neutralSummary,
        'summarySource': summarySource,
        'category': category,
        'outletCount': outletCount,
        'publishedAgo': publishedAgo,
        'publishedAt': publishedAt,
        'sourceName': sourceName,
        'articleUrl': articleUrl,
        'imageUrl': imageUrl,
        'semanticLabel': semanticLabel,
        'outlets': outlets,
        'isBreaking': isBreaking,
      };

  static String _requiredString(Map<String, dynamic> map, String key) {
    final value = _optionalString(map[key]);
    if (value == null) throw FormatException('Story is missing $key');
    return value;
  }

  static String _requiredUrl(Map<String, dynamic> map, String key) {
    final value = _requiredString(map, key);
    final uri = Uri.tryParse(value);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw FormatException('Story contains an invalid $key');
    }
    return value;
  }

  static String? _optionalString(dynamic value) {
    if (value is! String) return null;
    final result = value.trim();
    return result.isEmpty ? null : result;
  }

  static int _safeInt(dynamic value, int fallback) {
    if (value is int && value >= 0) return value;
    if (value is num && value.isFinite && value >= 0) return value.toInt();
    return fallback;
  }

  static List<Map<String, String>> _parseOutlets(dynamic value) {
    if (value is! List) return [];
    return value.whereType<Map>().map((item) {
      final name = _optionalString(item['name']);
      final url = _optionalString(item['articleUrl'] ?? item['url']);
      if (name == null || url == null) return null;
      final uri = Uri.tryParse(url);
      if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
        return null;
      }
      return <String, String>{
        'name': name,
        'lean': _optionalString(item['lean']) ?? 'Unknown',
        'framing': _optionalString(item['framing']) ?? '',
        'articleUrl': url,
      };
    }).whereType<Map<String, String>>().toList();
  }
}

class NewsFeedScreen extends StatefulWidget {
  const NewsFeedScreen({super.key});

  @override
  State<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen> {
  static const _categories = [
    'All',
    'Technology',
    'Business',
    'World',
    'Politics',
    'Climate',
    'Science',
    'Health',
  ];

  final _pageController = PageController();
  final _searchController = TextEditingController();
  List<StoryModel> _stories = [];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _loading = true;
  bool _refreshing = false;
  bool _searching = false;
  String? _errorMessage;

  List<StoryModel> get _visibleStories {
    final filtered = _selectedCategory == 'All'
        ? _stories
        : _stories.where((s) => s.category == _selectedCategory).toList();
    if (_searchQuery.isEmpty) return filtered;
    final q = _searchQuery.toLowerCase();
    return filtered
        .where((s) =>
            s.headline.toLowerCase().contains(q) ||
            s.neutralSummary.toLowerCase().contains(q) ||
            s.sourceName.toLowerCase().contains(q))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStories() async {
    if (!mounted) return;
    setState(() => _loading = true);
    List<Map<String, dynamic>> raw = [];
    String? errorMessage;
    try {
      raw = await LiveNewsService.fetchLiveStories(_categories.skip(1).toList());
    } on NewsServiceException catch (error) {
      errorMessage = error.message;
    }
    final parsed = <StoryModel>[];
    final seen = <String>{};
    for (final item in raw) {
      try {
        final story = StoryModel.fromMap(item);
        if (seen.add(story.id)) parsed.add(story);
      } on FormatException {
        // Skip malformed backend records.
      }
    }
    if (!mounted) return;
    setState(() {
      _stories = parsed;
      _errorMessage = errorMessage;
      _loading = false;
      _refreshing = false;
    });
  }

  Future<void> _refreshStories() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    await _loadStories();
  }

  void _openStory(StoryModel story) {
    context.push(AppRoutes.storyDetailScreen, extra: story.toMap());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _searching ? _buildSearchView() : _buildFeedView(),
      ),
    );
  }

  Widget _buildFeedView() {
    final stories = _visibleStories;
    return Column(
      children: [
        _buildAppBar(),
        _buildCategoryRow(),
        Expanded(
          child: stories.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _refreshStories,
                  child: PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    itemCount: stories.length,
                    itemBuilder: (_, index) => _StoryPage(
                      story: stories[index],
                      onReadMore: () => _openStory(stories[index]),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final title = LiveNewsService.isConfigured
        ? (_errorMessage ?? 'No stories found.')
        : 'News service not configured';
    final subtitle = LiveNewsService.isConfigured
        ? 'Please try again.'
        : 'Connect the app to your HTTPS news backend with BACKEND_BASE_URL.';
    return EmptyStateWidget(
      icon: Icons.newspaper_rounded,
      title: title,
      subtitle: subtitle,
      ctaLabel: 'Try again',
      onCta: _loadStories,
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/app_logo.png',
              width: 34,
              height: 34,
              fit: BoxFit.cover,
              semanticLabel: 'Truth logo',
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Truth',
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Search',
            onPressed: () => setState(() => _searching = true),
            icon: const Icon(Icons.search_rounded, color: Colors.white),
          ),
          IconButton(
            tooltip: 'Saved stories',
            onPressed: () => context.push(AppRoutes.bookmarksScreen),
            icon: const Icon(Icons.bookmark_border_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow() {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final category = _categories[index];
          final selected = category == _selectedCategory;
          return ChoiceChip(
            label: Text(category),
            selected: selected,
            onSelected: (_) => setState(() => _selectedCategory = category),
          );
        },
      ),
    );
  }

  Widget _buildSearchView() {
    final results = _visibleStories;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => setState(() {
                  _searching = false;
                  _searchQuery = '';
                  _searchController.clear();
                }),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (value) => setState(() => _searchQuery = value.trim()),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Search current news…',
                    hintStyle: TextStyle(color: Colors.white38),
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.white54),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: results.isEmpty
              ? Center(
                  child: Text(
                    _searchQuery.isEmpty ? 'Search for a story.' : 'No stories found.',
                    style: const TextStyle(color: Colors.white54),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, index) => ListTile(
                    tileColor: const Color(0xFF151515),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    title: Text(results[index].headline, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      '${results[index].sourceName} · ${results[index].publishedAgo}',
                      style: const TextStyle(color: Colors.white54),
                    ),
                    onTap: () => _openStory(results[index]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _StoryPage extends StatelessWidget {
  final StoryModel story;
  final VoidCallback onReadMore;

  const _StoryPage({required this.story, required this.onReadMore});

  String _shortSummary(String text) {
    final words = text.trim().split(RegExp(r'\s+'));
    return words.length <= 60 ? text : '${words.take(60).join(' ')}…';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: const Color(0xFF0A0A1A)),
        if (story.imageUrl.isNotEmpty)
          CustomImageWidget(
            imageUrl: story.imageUrl,
            fit: BoxFit.cover,
            semanticLabel: story.semanticLabel,
          ),
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black87],
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).padding.bottom + 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(story.category, style: const TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${story.sourceName} · ${story.publishedAgo}',
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                story.headline,
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _shortSummary(story.neutralSummary),
                style: const TextStyle(color: Colors.white70, height: 1.5),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.source_rounded, size: 14, color: Colors.white54),
                  const SizedBox(width: 5),
                  Text('${story.outletCount} source${story.outletCount == 1 ? '' : 's'}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: onReadMore,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                    label: const Text('Read More'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
