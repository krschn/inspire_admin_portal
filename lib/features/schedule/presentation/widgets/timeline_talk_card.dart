import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../talks/domain/entities/talk.dart';
import '../../../talks/presentation/providers/talks_provider.dart';
import '../../../talks/presentation/widgets/talk_form_dialog.dart';
import '../providers/schedule_filter_provider.dart';

class TimelineTalkCard extends ConsumerWidget {
  final Talk talk;

  const TimelineTalkCard({super.key, required this.talk});

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(trackByNumberProvider(talk.track));
    final trackColor = track != null ? _parseColor(track.trackColor) : Colors.grey;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Track color bar
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: trackColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: Time, duration, venue
                    Row(
                      children: [
                        Text(
                          _formatTime(talk.date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            talk.duration,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        const Spacer(),
                        if (talk.venue.isNotEmpty) ...[
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              talk.venue,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Title
                    Text(
                      talk.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Speakers
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: talk.speakers.map((speaker) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 14,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    speaker.name,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                        // Actions
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _editTalk(context, ref),
                          tooltip: 'Edit',
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete,
                            size: 20,
                            color: theme.colorScheme.error,
                          ),
                          onPressed: () => _deleteTalk(context, ref),
                          tooltip: 'Delete',
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editTalk(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      builder: (context) => TalkFormDialog(
        talk: talk,
        onSubmit: (updatedTalk) =>
            ref.read(talksProvider.notifier).updateTalk(updatedTalk),
      ),
    );
  }

  Future<void> _deleteTalk(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Talk'),
        content: Text('Are you sure you want to delete "${talk.title}"?'),
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

    if (confirmed == true && talk.id != null) {
      ref.read(talksProvider.notifier).deleteTalk(talk.id!);
    }
  }
}
