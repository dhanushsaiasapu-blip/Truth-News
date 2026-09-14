import 'package:dio/dio.dart';

/// Production news client. No provider credentials are shipped in the app.
/// Configure the HTTPS backend with --dart-define=BACKEND_BASE_URL=....
class NewsServiceException implements Exception {
  final String message;
  const NewsServiceException(this.message);

  @override
  String toString() => message;
}

class LiveNewsService {
  LiveNewsService._();

  static const String _configuredBaseUrl =
      String.fromEnvironment('BACKEND_BASE_URL');

  static String get baseUrl => _configuredBaseUrl.trim().replaceFirst(
        RegExp(r'/+$'),
        '',
      );

  static bool get isConfigured {
    final uri = Uri.tryParse(baseUrl);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty;
  }

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: const {'Accept': 'application/json'},
      responseType: ResponseType.json,
    ),
  );

  /// Expected backend response: {"articles": [...]}.
  /// Invalid records are discarded so malformed upstream data cannot crash
  /// the UI. The backend owns provider/API credentials and any AI processing.
  static Future<List<Map<String, dynamic>>> fetchLiveStories(
    List<String> categories,
  ) async {
    if (!isConfigured) return [];
    try {
      final response = await _dio.get<dynamic>(
        '$baseUrl/news',
        queryParameters: {
          if (categories.isNotEmpty && !categories.contains('All'))
            'categories': categories.join(','),
        },
      );
      final data = response.data;
      final rawArticles = data is Map ? data['articles'] : data;
      if (rawArticles is! List) {
        throw const NewsServiceException('News service returned an invalid response.');
      }
      return rawArticles
          .whereType<Map>()
          .map((article) => Map<String, dynamic>.from(article))
          .map(_normaliseStory)
          .whereType<Map<String, dynamic>>()
          .toList();
    } on DioException catch (error) {
      final networkFailure = error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout;
      if (networkFailure) {
        throw const NewsServiceException('No internet connection. Check your connection and try again.');
      }
      throw const NewsServiceException('News is temporarily unavailable. Please try again later.');
    } on NewsServiceException {
      rethrow;
    } catch (_) {
      throw const NewsServiceException('News is temporarily unavailable. Please try again later.');
    }
  }

  static Map<String, dynamic>? _normaliseStory(Map<String, dynamic> raw) {
    final id = _nonEmptyString(raw['id']);
    final headline = _nonEmptyString(raw['headline'] ?? raw['title']);
    final category = _nonEmptyString(raw['category']) ?? 'World';
    final articleUrl = _validHttpUrl(raw['articleUrl'] ?? raw['url']);
    if (id == null || headline == null || articleUrl == null) return null;

    final summary = _nonEmptyString(
          raw['neutralSummary'] ?? raw['summary'] ?? raw['description'],
        ) ??
        headline;
    final imageUrl = _validHttpUrl(raw['imageUrl'] ?? raw['urlToImage']);
    final publishedAt = _nonEmptyString(raw['publishedAt']);
    final sourceValue = raw['source'];
    final sourceName = _nonEmptyString(raw['sourceName']) ??
        (sourceValue is Map ? _nonEmptyString(sourceValue['name']) : null);

    final outlets = _parseOutlets(raw['outlets']);
    if (outlets.isEmpty) {
      outlets.add({
        'name': sourceName ?? 'Original source',
        'lean': 'Unknown',
        'framing': '',
        'articleUrl': articleUrl,
      });
    }

    return {
      'id': id,
      'headline': headline,
      'neutralSummary': summary,
      'summarySource': _summarySource(raw['summarySource']),
      'category': category,
      'outletCount': outlets.length,
      'publishedAgo': _publishedLabel(publishedAt, raw['publishedAgo']),
      'publishedAt': publishedAt,
      'sourceName': sourceName ?? 'Unknown source',
      'articleUrl': articleUrl,
      'imageUrl': imageUrl ?? '',
      'semanticLabel': _nonEmptyString(raw['semanticLabel']) ?? headline,
      'outlets': outlets,
      'isBreaking': raw['isBreaking'] is bool ? raw['isBreaking'] : false,
    };
  }

  static List<Map<String, String>> _parseOutlets(dynamic value) {
    if (value is! List) return [];
    final outlets = <Map<String, String>>[];
    for (final item in value) {
      if (item is! Map) continue;
      final name = _nonEmptyString(item['name']);
      final url = _validHttpUrl(item['articleUrl'] ?? item['url']);
      if (name == null || url == null) continue;
      outlets.add({
        'name': name,
        'lean': _nonEmptyString(item['lean']) ?? 'Unknown',
        'framing': _nonEmptyString(item['framing']) ?? '',
        'articleUrl': url,
      });
    }
    return outlets;
  }

  static String _summarySource(dynamic value) {
    return value == 'ai' ? 'ai' : 'source';
  }

  static String? _nonEmptyString(dynamic value) {
    if (value is! String) return null;
    final result = value.trim();
    return result.isEmpty ? null : result;
  }

  static String? _validHttpUrl(dynamic value) {
    final string = _nonEmptyString(value);
    if (string == null) return null;
    final uri = Uri.tryParse(string);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return null;
    }
    return string;
  }

  static String _publishedLabel(dynamic publishedAt, dynamic fallback) {
    final fallbackLabel = _nonEmptyString(fallback);
    final timestamp = _nonEmptyString(publishedAt);
    if (timestamp == null) {
      return fallbackLabel ?? 'Publication time unavailable';
    }
    final parsed = DateTime.tryParse(timestamp)?.toLocal();
    if (parsed == null) return fallbackLabel ?? 'Publication time unavailable';
    final delta = DateTime.now().difference(parsed);
    if (delta.isNegative || delta.inMinutes < 1) return 'Just now';
    if (delta.inMinutes < 60) return '${delta.inMinutes}m ago';
    if (delta.inHours < 24) return '${delta.inHours}h ago';
    if (delta.inDays < 7) return '${delta.inDays}d ago';
    return '${parsed.day}/${parsed.month}/${parsed.year}';
  }
}
