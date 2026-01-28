import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/talk.dart';

class TalkCard extends StatelessWidget {
  final Talk talk;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TalkCard({
    super.key,
    required this.talk,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        talk.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(talk.date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: onEdit,
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  color: theme.colorScheme.error,
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
              ],
            ),
            if (talk.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                talk.description,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (talk.track != 0)
                  _buildChip(context, Icons.category, talk.track.toString()),
                if (talk.venue.isNotEmpty)
                  _buildChip(context, Icons.location_on, talk.venue),
                if (talk.duration.isNotEmpty)
                  _buildChip(context, Icons.schedule, talk.duration),
              ],
            ),
            if (talk.speakers.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: talk.speakers.map((speaker) {
                  return Chip(
                    avatar: speaker.image.isNotEmpty
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(speaker.image),
                          )
                        : const CircleAvatar(
                            child: Icon(Icons.person, size: 16),
                          ),
                    label: Text(speaker.name),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
            if (talk.liveLink.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.link, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      talk.liveLink,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
