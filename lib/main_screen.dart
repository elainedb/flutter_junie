import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'services/youtube_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final YouTubeService _yt = YouTubeService();
  late Future<List<VideoItem>> _future;

  static const List<String> _channels = <String>[
    'UCynoa1DjwnvHAowA_jiMEAQ',
    'UCK0KOjX3beyB9nzonls0cuw',
    'UCACkIrvrGAQ7kuc0hMVwvmA',
    'UCtWRAKKvOEA0CXOue9BG8ZA',
  ];

  @override
  void initState() {
    super.initState();
    _future = _yt.fetchCombinedVideos(_channels);
  }

  Future<void> _openVideo(String id) async {
    final url = 'https://www.youtube.com/watch?v=$id';
    if (!await launchUrlString(url, mode: LaunchMode.externalApplication)) {
      // Fallback to in-app web view if external fails
      await launchUrlString(url, mode: LaunchMode.platformDefault);
    }
  }

  String _fmtDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Latest Videos')),
      body: FutureBuilder<List<VideoItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Failed to load videos. Please check your API key configuration and network.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }
          final items = snapshot.data ?? <VideoItem>[];
          if (items.isEmpty) {
            return const Center(child: Text('No videos found.'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final v = items[index];
              return ListTile(
                leading: v.thumbnailUrl.isNotEmpty
                    ? Image.network(v.thumbnailUrl, width: 100, fit: BoxFit.cover)
                    : const SizedBox(width: 100, height: 56),
                title: Text(v.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text('${v.channelTitle} • ${_fmtDate(v.publishedAt)}'),
                onTap: () => _openVideo(v.videoId),
              );
            },
          );
        },
      ),
    );
  }
}
