import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tracks/domain/entities/track.dart';
import '../../../tracks/presentation/providers/tracks_provider.dart';
import '../../../tracks/presentation/widgets/track_form_dialog.dart';

class TracksManagementSheet extends ConsumerWidget {
  const TracksManagementSheet({super.key});

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
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.25,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Manage Tracks',
                      style: theme.textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _addTrack(context, ref),
                      tooltip: 'Add Track',
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Content
              Expanded(
                child: tracksAsync.when(
                  data: (tracks) {
                    if (tracks.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.category_outlined,
                              size: 64,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No tracks yet',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            FilledButton.tonalIcon(
                              onPressed: () => _addTrack(context, ref),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Track'),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: tracks.length,
                      itemBuilder: (context, index) {
                        final track = tracks[index];
                        return _buildTrackTile(context, ref, track);
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Error loading tracks: $error',
                        style: TextStyle(color: theme.colorScheme.error),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrackTile(BuildContext context, WidgetRef ref, Track track) {
    final theme = Theme.of(context);
    final trackColor = _parseColor(track.trackColor);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${track.trackNumber}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: trackColor.computeLuminance() > 0.5
                    ? Colors.black
                    : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text('Track ${track.trackNumber}'),
        subtitle: Text(track.trackDescription),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editTrack(context, ref, track),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: Icon(Icons.delete, color: theme.colorScheme.error),
              onPressed: () => _deleteTrack(context, ref, track),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addTrack(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      builder: (context) => TrackFormDialog(
        onSubmit: (track) => ref.read(tracksProvider.notifier).createTrack(track),
      ),
    );
  }

  Future<void> _editTrack(
      BuildContext context, WidgetRef ref, Track track) async {
    await showDialog(
      context: context,
      builder: (context) => TrackFormDialog(
        track: track,
        onSubmit: (updatedTrack) =>
            ref.read(tracksProvider.notifier).updateTrack(updatedTrack),
      ),
    );
  }

  Future<void> _deleteTrack(
      BuildContext context, WidgetRef ref, Track track) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Track'),
        content: Text(
            'Are you sure you want to delete Track ${track.trackNumber} (${track.trackDescription})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && track.id != null) {
      ref.read(tracksProvider.notifier).deleteTrack(track.id!);
    }
  }
}
