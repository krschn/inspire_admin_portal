import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../talks/presentation/providers/selected_event_provider.dart';
import '../../../talks/presentation/widgets/event_dropdown.dart';
import '../providers/tracks_provider.dart';
import '../widgets/track_card.dart';
import '../widgets/track_excel_upload_button.dart';
import '../widgets/track_form_dialog.dart';

class TracksPage extends ConsumerWidget {
  const TracksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedEvent = ref.watch(selectedEventProvider);
    final tracksAsync = ref.watch(tracksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Management'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: TrackExcelUploadButton(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(child: EventDropdown()),
                if (selectedEvent != null) ...[
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () =>
                        ref.read(tracksProvider.notifier).refresh(),
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: selectedEvent == null
                ? const Center(
                    child: Text('Please select an event to view tracks'),
                  )
                : tracksAsync.when(
                    data: (tracks) {
                      if (tracks.isEmpty) {
                        return const Center(
                          child: Text('No tracks found for this event'),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: tracks.length,
                        itemBuilder: (context, index) {
                          final track = tracks[index];
                          return TrackCard(
                            track: track,
                            onEdit: () => _showEditDialog(context, ref, track),
                            onDelete: () =>
                                _showDeleteConfirmation(context, ref, track),
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text('Error: $error'),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () =>
                                ref.read(tracksProvider.notifier).refresh(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: selectedEvent == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showCreateDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add Track'),
            ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => TrackFormDialog(
        onSubmit: (track) =>
            ref.read(tracksProvider.notifier).createTrack(track),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, track) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Track'),
        content: Text(
          'Are you sure you want to delete "Track ${track.trackNumber} - ${track.trackDescription}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(tracksProvider.notifier).deleteTrack(track.id!);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, track) {
    showDialog(
      context: context,
      builder: (context) => TrackFormDialog(
        track: track,
        onSubmit: (updatedTrack) =>
            ref.read(tracksProvider.notifier).updateTrack(updatedTrack),
      ),
    );
  }
}
