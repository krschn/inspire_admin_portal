import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../talks/domain/entities/talk.dart';
import '../../../talks/presentation/providers/talks_provider.dart';
import '../../../tracks/domain/entities/track.dart';
import '../../../tracks/presentation/providers/tracks_provider.dart';

/// Notifier for the selected track filter (supports multiple tracks).
class SelectedTrackFilterNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => {};

  void toggle(int trackNumber) {
    if (state.contains(trackNumber)) {
      state = {...state}..remove(trackNumber);
    } else {
      state = {...state, trackNumber};
    }
  }

  void selectAll() {
    state = {};
  }

  void clear() {
    state = {};
  }
}

/// Provider for the currently selected track filter.
/// Empty set means "All Tracks" is selected.
final selectedTrackFilterProvider =
    NotifierProvider<SelectedTrackFilterNotifier, Set<int>>(
        SelectedTrackFilterNotifier.new);

/// Provider that returns talks filtered by the selected tracks.
final filteredTalksProvider = Provider<AsyncValue<List<Talk>>>((ref) {
  final talksAsync = ref.watch(talksProvider);
  final selectedTracks = ref.watch(selectedTrackFilterProvider);

  return talksAsync.whenData((talks) {
    if (selectedTracks.isEmpty) {
      return talks;
    }
    return talks.where((talk) => selectedTracks.contains(talk.track)).toList();
  });
});

/// A grouped entry for the timeline view.
class TimeSlot {
  final DateTime dateTime;
  final List<Talk> talks;

  const TimeSlot({
    required this.dateTime,
    required this.talks,
  });
}

/// Groups talks by their date first, then by start time within each date.
class GroupedSchedule {
  final Map<DateTime, List<TimeSlot>> groupedByDate;

  const GroupedSchedule({required this.groupedByDate});

  List<DateTime> get sortedDates {
    final dates = groupedByDate.keys.toList();
    dates.sort();
    return dates;
  }

  List<TimeSlot> getTimeSlotsForDate(DateTime date) {
    return groupedByDate[date] ?? [];
  }
}

/// Provider that groups talks by date and time slot for timeline view.
final groupedTalksProvider = Provider<AsyncValue<GroupedSchedule>>((ref) {
  final filteredTalksAsync = ref.watch(filteredTalksProvider);

  return filteredTalksAsync.whenData((talks) {
    // Group by date (year, month, day)
    final Map<DateTime, List<Talk>> byDate = {};

    for (final talk in talks) {
      final dateKey = DateTime(talk.date.year, talk.date.month, talk.date.day);
      byDate.putIfAbsent(dateKey, () => []).add(talk);
    }

    // For each date, group by time
    final Map<DateTime, List<TimeSlot>> result = {};

    for (final entry in byDate.entries) {
      final date = entry.key;
      final talksOnDate = entry.value;

      // Group by hour:minute
      final Map<DateTime, List<Talk>> byTime = {};
      for (final talk in talksOnDate) {
        final timeKey = DateTime(
          talk.date.year,
          talk.date.month,
          talk.date.day,
          talk.date.hour,
          talk.date.minute,
        );
        byTime.putIfAbsent(timeKey, () => []).add(talk);
      }

      // Convert to TimeSlot list sorted by time
      final timeSlots = byTime.entries.map((e) {
        return TimeSlot(dateTime: e.key, talks: e.value);
      }).toList();
      timeSlots.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      result[date] = timeSlots;
    }

    return GroupedSchedule(groupedByDate: result);
  });
});

/// Provider to look up a track by its number.
final trackByNumberProvider = Provider.family<Track?, int>((ref, trackNumber) {
  final tracksAsync = ref.watch(tracksProvider);
  final tracks = tracksAsync.value;
  if (tracks == null) return null;

  try {
    return tracks.firstWhere((t) => t.trackNumber == trackNumber);
  } catch (_) {
    return Track(
      trackNumber: trackNumber,
      trackDescription: 'Track $trackNumber',
      trackColor: '#808080',
    );
  }
});
