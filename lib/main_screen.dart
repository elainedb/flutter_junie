// ignore_for_file: deprecated_member_use
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'services/youtube_service.dart';
import 'viewmodels/video_view_model.dart';
import 'map_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  static const List<String> channels = <String>[
    'UCynoa1DjwnvHAowA_jiMEAQ',
    'UCK0KOjX3beyB9nzonls0cuw',
    'UCACkIrvrGAQ7kuc0hMVwvmA',
    'UCtWRAKKvOEA0CXOue9BG8ZA',
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VideoViewModel()..load(channels),
      child: const _MainScreenBody(),
    );
  }
}

class _MainScreenBody extends StatelessWidget {
  const _MainScreenBody();

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

  Future<void> _showFilterDialog(BuildContext context, List<VideoItem> items) async {
    final vm = context.read<VideoViewModel>();
    String? selectedChannel = vm.filterChannelId;
    String? selectedCountry = vm.filterCountry;
    // Build mapping of channelId -> channelTitle for display
    final Map<String, String> idToTitle = {
      for (final v in items) v.channelId: (v.channelTitle.isNotEmpty ? v.channelTitle : v.channelId)
    };
    final channelOptions = idToTitle.keys.toList();
    final countryOptions = items.map((e) => e.country ?? '').where((e) => e.isNotEmpty).toSet().toList();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Filter'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedChannel?.isEmpty == true ? null : selectedChannel,
                hint: const Text('Source Channel'),
                items: [
                  const DropdownMenuItem<String>(value: '', child: Text('All Channels')),
                  ...channelOptions.map((id) => DropdownMenuItem<String>(value: id, child: Text(idToTitle[id] ?? id))),
                ],
                onChanged: (val) => selectedChannel = (val ?? '').isEmpty ? null : val,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedCountry?.isEmpty == true ? null : selectedCountry,
                hint: const Text('Country'),
                items: [
                  const DropdownMenuItem<String>(value: '', child: Text('All Countries')),
                  ...countryOptions.map((c) => DropdownMenuItem<String>(value: c, child: Text(c))),
                ],
                onChanged: (val) => selectedCountry = (val ?? '').isEmpty ? null : val,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                vm.setFilter(channelId: selectedChannel, country: selectedCountry);
                Navigator.pop(ctx);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSortDialog(BuildContext context) async {
    final vm = context.read<VideoViewModel>();
    var field = vm.sortField;
    var order = vm.sortOrder;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Sort'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<SortField>(
                value: SortField.publishedDate,
                groupValue: field,
                onChanged: (v) => field = v ?? field,
                title: const Text('Publication Date'),
              ),
              RadioListTile<SortField>(
                value: SortField.recordingDate,
                groupValue: field,
                onChanged: (v) => field = v ?? field,
                title: const Text('Recording Date'),
              ),
              const Divider(),
              RadioListTile<SortOrder>(
                value: SortOrder.desc,
                groupValue: order,
                onChanged: (v) => order = v ?? order,
                title: const Text('Newest to Oldest'),
              ),
              RadioListTile<SortOrder>(
                value: SortOrder.asc,
                groupValue: order,
                onChanged: (v) => order = v ?? order,
                title: const Text('Oldest to Newest'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                vm.setSort(field, order);
                Navigator.pop(ctx);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Latest Videos (${vm.items.length})'),
            actions: [
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<Widget>(builder: (_) => const MapScreen()),
                  );
                },
                icon: const Icon(Icons.map, color: Colors.white),
                label: const Text('View Map', style: TextStyle(color: Colors.white)),
              ),
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh),
                onPressed: vm.loading
                    ? null
                    : () => vm.load(MainScreen.channels, forceRefresh: true),
              ),
              IconButton(
                tooltip: 'Filter',
                icon: const Icon(Icons.filter_list),
                onPressed: vm.loading ? null : () => _showFilterDialog(context, vm.items),
              ),
              IconButton(
                tooltip: 'Sort',
                icon: const Icon(Icons.sort),
                onPressed: vm.loading ? null : () => _showSortDialog(context),
              ),
            ],
          ),
          body: _buildBody(context, vm),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, VideoViewModel vm) {
    if (vm.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Failed to load videos. Please check your API key configuration and network.\n\n${vm.error}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }
    final items = vm.items;
    if (items.isEmpty) {
      return const Center(child: Text('No videos found.'));
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final v = items[index];
        final tags = v.tags.isNotEmpty ? v.tags.join(', ') : '—';
        final locParts = <String>[];
        if ((v.city ?? '').isNotEmpty) locParts.add(v.city!);
        if ((v.country ?? '').isNotEmpty) locParts.add(v.country!);
        if (v.latitude != null && v.longitude != null) {
          locParts.add('(${v.latitude!.toStringAsFixed(4)}, ${v.longitude!.toStringAsFixed(4)})');
        }
        final location = locParts.isNotEmpty ? locParts.join(', ') : '—';
        final recDate = v.recordingDate != null ? _fmtDate(v.recordingDate!) : '—';

        return ListTile(
          leading: v.thumbnailUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: v.thumbnailUrl,
                  width: 120,
                  fit: BoxFit.cover,
                )
              : const SizedBox(width: 120, height: 68),
          title: Text(v.title, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${v.channelTitle} • ${_fmtDate(v.publishedAt)}'),
              Text('Tags: $tags', style: const TextStyle(fontSize: 12)),
              Text('Location: $location', style: const TextStyle(fontSize: 12)),
              Text('Recording Date: $recDate', style: const TextStyle(fontSize: 12)),
            ],
          ),
          onTap: () => _openVideo(v.videoId),
          isThreeLine: true,
        );
      },
    );
  }
}
