import 'package:flutter/foundation.dart';

import '../services/video_repository.dart';
import '../services/youtube_service.dart';

enum SortField { publishedDate, recordingDate }

enum SortOrder { desc, asc }

class VideoViewModel extends ChangeNotifier {
  VideoViewModel({VideoRepository? repository})
      : _repo = repository ?? VideoRepository();

  final VideoRepository _repo;

  // Source data
  List<VideoItem> _all = [];
  List<VideoItem> _visible = [];

  // Filters
  String? _filterChannelId;
  String? _filterCountry;

  // Sort
  SortField _sortField = SortField.publishedDate;
  SortOrder _sortOrder = SortOrder.desc;

  // State
  bool _loading = false;
  String? _error;

  List<VideoItem> get items => _visible;
  bool get loading => _loading;
  String? get error => _error;
  String? get filterChannelId => _filterChannelId;
  String? get filterCountry => _filterCountry;
  SortField get sortField => _sortField;
  SortOrder get sortOrder => _sortOrder;

  Future<void> load(List<String> channels, {bool forceRefresh = false}) async {
    _setLoading(true);
    try {
      final data = await _repo.getVideos(channels, forceRefresh: forceRefresh);
      _all = data;
      _applyFiltersAndSort();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void setFilter({String? channelId, String? country}) {
    _filterChannelId = channelId;
    _filterCountry = country;
    _applyFiltersAndSort();
  }

  void setSort(SortField field, SortOrder order) {
    _sortField = field;
    _sortOrder = order;
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    Iterable<VideoItem> list = _all;
    if (_filterChannelId != null && _filterChannelId!.isNotEmpty) {
      list = list.where((v) => v.channelId == _filterChannelId);
    }
    if (_filterCountry != null && _filterCountry!.isNotEmpty) {
      list = list.where((v) => (v.country ?? '').toLowerCase() == _filterCountry!.toLowerCase());
    }
    final sorted = list.toList();
    int compareDates(DateTime? a, DateTime? b) {
      if (a == null && b == null) return 0;
      if (a == null) return -1;
      if (b == null) return 1;
      return a.compareTo(b);
    }
    sorted.sort((a, b) {
      int cmp;
      if (_sortField == SortField.publishedDate) {
        cmp = a.publishedAt.compareTo(b.publishedAt);
      } else {
        cmp = compareDates(a.recordingDate, b.recordingDate);
      }
      return _sortOrder == SortOrder.asc ? cmp : -cmp;
    });
    _visible = sorted;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
