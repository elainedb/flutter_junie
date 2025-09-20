import 'package:flutter/foundation.dart';

import 'db_helper.dart';
import 'youtube_service.dart';

class VideoRepository {
  VideoRepository({YouTubeService? service, DbHelper? dbHelper})
      : _service = service ?? YouTubeService(),
        _db = dbHelper ?? DbHelper();

  final YouTubeService _service;
  final DbHelper _db;

  static const Duration cacheTtl = Duration(hours: 24);

  Future<List<VideoItem>> getVideos(List<String> channels, {bool forceRefresh = false}) async {
    final last = await _db.getLastRefresh();
    final now = DateTime.now();
    if (!forceRefresh && last != null && now.difference(last) < cacheTtl) {
      final rows = await _db.getAllVideos();
      return rows.map(_fromRow).toList();
    }

    // Fetch remote
    final combined = await _service.fetchCombinedVideos(channels);

    // Persist to cache
    await _db.clearVideos();
    await _db.upsertVideos(combined.map(_toRow).toList());
    await _db.setLastRefresh(now);

    return combined;
  }

  Map<String, Object?> _toRow(VideoItem v) => {
        'id': v.videoId,
        'title': v.title,
        'channel_id': v.channelId,
        'channel_title': v.channelTitle,
        'published_at': v.publishedAt.toIso8601String(),
        'thumbnail_url': v.thumbnailUrl,
        'tags': v.tags.join(','),
        'country': v.country,
        'city': v.city,
        'latitude': v.latitude,
        'longitude': v.longitude,
        'recording_date': v.recordingDate?.toIso8601String(),
      };

  VideoItem _fromRow(Map<String, Object?> row) => VideoItem(
        videoId: (row['id'] as String?) ?? '',
        title: (row['title'] as String?) ?? '',
        channelId: (row['channel_id'] as String?) ?? '',
        channelTitle: (row['channel_title'] as String?) ?? '',
        publishedAt: DateTime.tryParse((row['published_at'] as String?) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        thumbnailUrl: (row['thumbnail_url'] as String?) ?? '',
        tags: ((row['tags'] as String?) ?? '')
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        country: row['country'] as String?,
        city: row['city'] as String?,
        latitude: (row['latitude'] is num) ? (row['latitude'] as num).toDouble() : null,
        longitude: (row['longitude'] is num) ? (row['longitude'] as num).toDouble() : null,
        recordingDate: (row['recording_date'] as String?) != null
            ? DateTime.tryParse(row['recording_date'] as String)
            : null,
      );
}
