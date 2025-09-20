import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'services/video_repository.dart';
import 'services/youtube_service.dart';
import 'viewmodels/video_view_model.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Map')),
      body: const _MapBody(),
    );
  }
}

class _MapBody extends StatefulWidget {
  const _MapBody();

  @override
  State<_MapBody> createState() => _MapBodyState();
}

class _MapBodyState extends State<_MapBody> {
  final MapController _mapController = MapController();
  final VideoRepository _repo = VideoRepository();

  List<VideoItem> _videos = [];
  List<VideoItem> _videosWithLocation = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Prefer the items already loaded in the MainScreen if available
      final vm = context.read<VideoViewModel?>();
      List<VideoItem> source = [];
      if (vm != null && vm.items.isNotEmpty) {
        source = vm.items;
      } else {
        // Fallback to cached DB (no network)
        source = await _repo.getCachedVideos();
      }
      final withLoc = source
          .where((v) => v.latitude != null && v.longitude != null)
          .toList();
      setState(() {
        _videos = source;
        _videosWithLocation = withLoc;
        _loading = false;
        _error = null;
      });
      // Fit bounds after first frame if we have markers
      if (withLoc.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _fitToMarkers());
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _fitToMarkers() {
    if (_videosWithLocation.isEmpty) return;
    final points = _videosWithLocation
        .map((v) => LatLng(v.latitude!, v.longitude!))
        .toList();
    // Handle single point by creating a tiny bounds around it
    LatLngBounds bounds;
    if (points.length == 1) {
      final p = points.first;
      bounds = LatLngBounds.fromPoints([
        LatLng(p.latitude + 0.0005, p.longitude + 0.0005),
        LatLng(p.latitude - 0.0005, p.longitude - 0.0005),
      ]);
    } else {
      bounds = LatLngBounds.fromPoints(points);
    }
    try {
      final camera = CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(32),
      ).fit(_mapController.camera);
      _mapController.move(camera.center, camera.zoom);
    } catch (_) {
      // ignore if controller not ready
    }
  }

  String _fmtDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  Future<void> _openVideo(String id) async {
    final url = 'https://www.youtube.com/watch?v=$id';
    if (!await launchUrlString(url, mode: LaunchMode.externalApplication)) {
      await launchUrlString(url, mode: LaunchMode.platformDefault);
    }
  }

  void _onMarkerTap(VideoItem v) {
    final maxHeight = MediaQuery.of(context).size.height * 0.25;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      builder: (ctx) {
        final locParts = <String>[];
        if ((v.city ?? '').isNotEmpty) locParts.add(v.city!);
        if ((v.country ?? '').isNotEmpty) locParts.add(v.country!);
        if (v.latitude != null && v.longitude != null) {
          locParts.add('(${v.latitude!.toStringAsFixed(4)}, ${v.longitude!.toStringAsFixed(4)})');
        }
        final location = locParts.isNotEmpty ? locParts.join(', ') : '—';
        final recDate = v.recordingDate != null ? _fmtDate(v.recordingDate!) : '—';
        final tags = v.tags.isNotEmpty ? v.tags.join(', ') : '—';
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (v.thumbnailUrl.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: v.thumbnailUrl,
                        width: 120,
                        height: 68,
                        fit: BoxFit.cover,
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(v.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('${v.channelTitle} • ${_fmtDate(v.publishedAt)}', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Tags: $tags', style: const TextStyle(fontSize: 12)),
                Text('Location: $location', style: const TextStyle(fontSize: 12)),
                Text('Recording Date: $recDate', style: const TextStyle(fontSize: 12)),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open in YouTube'),
                    onPressed: () => _openVideo(v.videoId),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Failed to load map data: $_error'));
    }

    final markers = _videosWithLocation
        .map((v) => Marker(
              point: LatLng(v.latitude!, v.longitude!),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () => _onMarkerTap(v),
                child: const Icon(Icons.location_on, color: Colors.red, size: 36),
              ),
            ))
        .toList();

    return FlutterMap(
      mapController: _mapController,
      options: const MapOptions(
        initialCenter: LatLng(0, 0),
        initialZoom: 2,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.example.flutter_junie',
        ),
        MarkerLayer(markers: markers),
        if (_videosWithLocation.isEmpty)
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'No videos with location found',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
