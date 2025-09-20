import 'dart:convert';

import 'package:http/http.dart' as http;
import '../config/config.dart';

class VideoItem {
  VideoItem({
    required this.videoId,
    required this.title,
    required this.channelId,
    required this.channelTitle,
    required this.publishedAt,
    required this.thumbnailUrl,
    this.tags = const [],
    this.country,
    this.city,
    this.latitude,
    this.longitude,
    this.recordingDate,
  });

  final String videoId;
  final String title;
  final String channelId;
  final String channelTitle;
  final DateTime publishedAt;
  final String thumbnailUrl;
  final List<String> tags;
  final String? country;
  final String? city;
  final double? latitude;
  final double? longitude;
  final DateTime? recordingDate;
}

class YouTubeService {
  YouTubeService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // Simple in-memory cache for reverse geocoding to reduce requests
  final Map<String, Map<String, String?>> _reverseGeoCache = {};

  Future<Map<String, String?>> _reverseGeocode(double lat, double lng) async {
    // Round to 3 decimals (~100m) to improve cache hits
    final key = '${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}';
    if (_reverseGeoCache.containsKey(key)) return _reverseGeoCache[key]!;

    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'jsonv2',
      'lat': lat.toString(),
      'lon': lng.toString(),
      'zoom': '10',
      'addressdetails': '1',
    });
    try {
      final resp = await _client.get(uri, headers: {
        'User-Agent': 'flutter_junie/1.0 (reverse-geocoding)'
      });
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final addr = (data['address'] as Map<String, dynamic>?) ?? const {};
        final String? city = (addr['city'] as String?) ?? (addr['town'] as String?) ?? (addr['village'] as String?) ?? (addr['hamlet'] as String?);
        final String? country = addr['country'] as String?;
        final result = <String, String?>{'city': city, 'country': country};
        _reverseGeoCache[key] = result;
        return result;
      }
    } catch (_) {
      // ignore errors and fall back
    }
    final fallback = <String, String?>{'city': null, 'country': null};
    _reverseGeoCache[key] = fallback;
    return fallback;
  }

  // Fetch ALL videos for a channel using Search API (videos only), then enrich via videos.list
  Future<List<VideoItem>> _fetchChannelVideos(String channelId) async {
    // 1) Use search.list to get ALL video IDs for the channel (videos only), paginating by nextPageToken
    final prelim = <VideoItem>[];
    String? pageToken;
    do {
      final searchUri = Uri.https('www.googleapis.com', '/youtube/v3/search', {
        'key': youtubeApiKey,
        'part': 'snippet',
        'channelId': channelId,
        'type': 'video',
        'order': 'date',
        'maxResults': '50',
        if (pageToken != null) 'pageToken': pageToken,
      });
      final sResp = await _client.get(searchUri);
      if (sResp.statusCode != 200) {
        throw Exception('Failed to search videos for channel $channelId: ${sResp.statusCode}');
      }
      final sData = json.decode(sResp.body) as Map<String, dynamic>;
      pageToken = sData['nextPageToken'] as String?;
      final items = (sData['items'] as List<dynamic>? ?? <dynamic>[]);
      for (final item in items) {
        final map = item as Map<String, dynamic>;
        final id = (map['id'] as Map<String, dynamic>? ?? const {})['videoId'] as String? ?? '';
        if (id.isEmpty) continue;
        final snippet = (map['snippet'] as Map<String, dynamic>? ?? const {});
        final thumbnails = (snippet['thumbnails'] as Map<String, dynamic>? ?? const {});
        final thumb = (thumbnails['medium'] ?? thumbnails['default'] ?? thumbnails['high'])
                as Map<String, dynamic>? ??
            const {};
        prelim.add(
          VideoItem(
            videoId: id,
            title: (snippet['title'] as String?) ?? '',
            channelId: (snippet['channelId'] as String?) ?? channelId,
            channelTitle: (snippet['channelTitle'] as String?) ?? '',
            publishedAt: DateTime.tryParse((snippet['publishedAt'] as String?) ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0),
            thumbnailUrl: (thumb['url'] as String?) ?? '',
          ),
        );
      }
    } while (pageToken != null && pageToken.isNotEmpty);

    if (prelim.isEmpty) return prelim;

    // 2) Enrich via videos endpoint in batches of 50
    final Map<String, Map<String, dynamic>> detailsById = {};
    for (var i = 0; i < prelim.length; i += 50) {
      final batchIds = prelim.skip(i).take(50).map((e) => e.videoId).join(',');
      final videosUri = Uri.https('www.googleapis.com', '/youtube/v3/videos', {
        'key': youtubeApiKey,
        'part': 'snippet,recordingDetails',
        'id': batchIds,
        'maxResults': '50',
      });
      final vResp = await _client.get(videosUri);
      if (vResp.statusCode != 200) continue;
      final vData = json.decode(vResp.body) as Map<String, dynamic>;
      final vItems = (vData['items'] as List<dynamic>? ?? <dynamic>[]);
      for (final it in vItems) {
        final m = it as Map<String, dynamic>;
        final vid = (m['id'] as String?) ?? '';
        if (vid.isNotEmpty) detailsById[vid] = m;
      }
    }

    // 3) Merge extra details and reverse geocode
    for (var i = 0; i < prelim.length; i++) {
      final base = prelim[i];
      final details = detailsById[base.videoId];
      if (details == null) continue;
      final snippet = (details['snippet'] as Map<String, dynamic>?) ?? const {};
      final rec = (details['recordingDetails'] as Map<String, dynamic>?) ?? const {};
      final tagsList = (snippet['tags'] as List?)?.whereType<String>().toList() ?? const <String>[];
      final loc = (rec['location'] as Map<String, dynamic>?) ?? const {};
      final locDesc = (rec['locationDescription'] as String?) ?? '';
      final double? lat = (loc['latitude'] is num) ? (loc['latitude'] as num).toDouble() : null;
      final double? lng = (loc['longitude'] is num) ? (loc['longitude'] as num).toDouble() : null;
      String? city;
      String? country;
      if (locDesc.isNotEmpty) {
        final parts = locDesc.split(',').map((e) => e.trim()).toList();
        if (parts.length >= 2) {
          city = parts[0].isNotEmpty ? parts[0] : null;
          country = parts.last.isNotEmpty ? parts.last : null;
        } else if (parts.length == 1) {
          country = parts[0];
        }
      }
      if (lat != null && lng != null) {
        try {
          final rev = await _reverseGeocode(lat, lng);
          city = rev['city'] ?? city;
          country = rev['country'] ?? country;
        } catch (_) {}
      }

      final String? recDateStr = rec['recordingDate'] as String?;
      final DateTime? recDate = recDateStr != null && recDateStr.isNotEmpty
          ? DateTime.tryParse(recDateStr)
          : null;

      prelim[i] = VideoItem(
        videoId: base.videoId,
        title: base.title,
        channelId: base.channelId,
        channelTitle: base.channelTitle,
        publishedAt: base.publishedAt,
        thumbnailUrl: base.thumbnailUrl,
        tags: tagsList,
        country: country,
        city: city,
        latitude: lat,
        longitude: lng,
        recordingDate: recDate,
      );
    }

    return prelim;
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
