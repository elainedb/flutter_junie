import 'dart:convert';

import 'package:http/http.dart' as http;
import '../config/config.dart';

class VideoItem {
  VideoItem({
    required this.videoId,
    required this.title,
    required this.channelTitle,
    required this.publishedAt,
    required this.thumbnailUrl,
  });

  final String videoId;
  final String title;
  final String channelTitle;
  final DateTime publishedAt;
  final String thumbnailUrl;
}

class YouTubeService {
  YouTubeService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // Fetch recent videos for a single channel
  Future<List<VideoItem>> _fetchChannelVideos(String channelId) async {
    final uri = Uri.https('www.googleapis.com', '/youtube/v3/search', {
      'key': youtubeApiKey,
      'part': 'snippet',
      'channelId': channelId,
      'maxResults': '10',
      'order': 'date',
      'type': 'video',
      // 'publishedAfter': DateTime.now().subtract(const Duration(days: 30)).toUtc().toIso8601String(),
    });

    final resp = await _client.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch videos for channel $channelId: ${resp.statusCode}');
    }
    final data = json.decode(resp.body) as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? <dynamic>[]);
    return items.map((dynamic item) {
      final map = item as Map<String, dynamic>;
      final id = map['id'] as Map<String, dynamic>?;
      final snippet = map['snippet'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final thumbnails = (snippet['thumbnails'] as Map<String, dynamic>? ?? <String, dynamic>{});
      final thumb = (thumbnails['medium'] ?? thumbnails['default'] ?? thumbnails['high']) as Map<String, dynamic>? ?? <String, dynamic>{};

      return VideoItem(
        videoId: (id?['videoId'] as String?) ?? '',
        title: (snippet['title'] as String?) ?? '',
        channelTitle: (snippet['channelTitle'] as String?) ?? '',
        publishedAt: DateTime.tryParse((snippet['publishedAt'] as String?) ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        thumbnailUrl: (thumb['url'] as String?) ?? '',
      );
    }).where((v) => v.videoId.isNotEmpty).toList();
  }

  // Fetch and combine videos from multiple channels and sort by date desc
  Future<List<VideoItem>> fetchCombinedVideos(List<String> channelIds) async {
    final futures = channelIds.map(_fetchChannelVideos);
    final results = await Future.wait(futures);
    final all = results.expand((e) => e).toList();
    all.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return all;
  }
}
