import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/selected_event_provider.dart';
import '../providers/talks_provider.dart';
import '../widgets/event_dropdown.dart';
import '../widgets/excel_upload_button.dart';
import '../widgets/talk_card.dart';
import '../widgets/talk_form_dialog.dart';

class TalksPage extends ConsumerWidget {
  const TalksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedEvent = ref.watch(selectedEventProvider);
    final talksAsync = ref.watch(talksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Talk Management'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: ExcelUploadButton(),
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
                    onPressed: () => ref.read(talksProvider.notifier).refresh(),
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
                    child: Text('Please select an event to view talks'),
                  )
                : talksAsync.when(
                    data: (talks) {
                      if (talks.isEmpty) {
                        return const Center(
                          child: Text('No talks found for this event'),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: talks.length,
                        itemBuilder: (context, index) {
                          final talk = talks[index];
                          return TalkCard(
                            talk: talk,
                            onEdit: () => _showEditDialog(context, ref, talk),
                            onDelete: () =>
                                _showDeleteConfirmation(context, ref, talk),
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
                                ref.read(talksProvider.notifier).refresh(),
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
              label: const Text('Add Talk'),
            ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => TalkFormDialog(
        onSubmit: (talk) => ref.read(talksProvider.notifier).createTalk(talk),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, talk) {
    showDialog(
      context: context,
      builder: (context) => TalkFormDialog(
        talk: talk,
        onSubmit: (updatedTalk) =>
            ref.read(talksProvider.notifier).updateTalk(updatedTalk),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, talk) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Talk'),
        content: Text('Are you sure you want to delete "${talk.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(talksProvider.notifier).deleteTalk(talk.id!);
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
}
