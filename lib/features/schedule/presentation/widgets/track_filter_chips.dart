import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tracks/presentation/providers/tracks_provider.dart';
import '../providers/schedule_filter_provider.dart';

class TrackFilterChips extends ConsumerWidget {
  const TrackFilterChips({super.key});

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(tracksProvider);
    final selectedTracks = ref.watch(selectedTrackFilterProvider);

    return tracksAsync.when(
      data: (tracks) {
        return SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // "All Tracks" chip
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: const Text('All Tracks'),
                  selected: selectedTracks.isEmpty,
                  onSelected: (_) {
                    ref.read(selectedTrackFilterProvider.notifier).selectAll();
                  },
                ),
              ),
              // Track chips
              ...tracks.map((track) {
                final isSelected = selectedTracks.contains(track.trackNumber);
                final trackColor = _parseColor(track.trackColor);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: trackColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    label: Text('Track ${track.trackNumber}: ${track.trackDescription}'),
                    selected: isSelected,
                    onSelected: (_) {
                      ref.read(selectedTrackFilterProvider.notifier).toggle(track.trackNumber);
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => SizedBox(
        height: 48,
        child: Center(
          child: Text(
            'Error loading tracks',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
    );
  }
}
