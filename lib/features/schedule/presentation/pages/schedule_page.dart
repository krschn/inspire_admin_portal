import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/widgets/user_menu.dart';
import '../../../talks/presentation/providers/talks_provider.dart';
import '../../../talks/presentation/widgets/event_dropdown.dart';
import '../../../talks/presentation/widgets/talk_form_dialog.dart';
import '../providers/schedule_filter_provider.dart';
import '../widgets/timeline_talk_card.dart';
import '../widgets/track_filter_chips.dart';
import '../widgets/tracks_management_sheet.dart';
import '../widgets/unified_excel_upload_button.dart';

class SchedulePage extends ConsumerWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupedScheduleAsync = ref.watch(groupedTalksProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspire Admin'),
        actions: [
          TextButton.icon(
            onPressed: () => _showTracksManagement(context),
            icon: const Icon(Icons.category),
            label: const Text('Manage Tracks'),
          ),
          const SizedBox(width: 8),
          const UnifiedExcelUploadButton(),
          const SizedBox(width: 8),
          const UserMenu(),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Event dropdown row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Expanded(child: EventDropdown()),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    ref.read(talksProvider.notifier).refresh();
                  },
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Track filter chips
          const TrackFilterChips(),
          const Divider(height: 1),
          // Timeline content
          Expanded(
            child: groupedScheduleAsync.when(
              data: (schedule) {
                final dates = schedule.sortedDates;

                if (dates.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_note,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No talks scheduled',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add talks using the + button or upload an Excel file',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: dates.length,
                  itemBuilder: (context, dateIndex) {
                    final date = dates[dateIndex];
                    final timeSlots = schedule.getTimeSlotsForDate(date);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (dateIndex > 0) const SizedBox(height: 24),
                        // Date header
                        _buildDateHeader(context, date),
                        const SizedBox(height: 12),
                        // Time slots
                        ...timeSlots.map((slot) => _buildTimeSlot(context, slot)),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading schedule',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        error.toString(),
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addTalk(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Talk'),
      ),
    );
  }

  Widget _buildDateHeader(BuildContext context, DateTime date) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            size: 18,
            color: theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 8),
          Text(
            dateFormat.format(date),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlot(BuildContext context, TimeSlot slot) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: slot.talks.map((talk) => TimelineTalkCard(talk: talk)).toList(),
      ),
    );
  }

  void _showTracksManagement(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TracksManagementSheet(),
    );
  }

  Future<void> _addTalk(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      builder: (context) => TalkFormDialog(
        onSubmit: (talk) => ref.read(talksProvider.notifier).createTalk(talk),
      ),
    );
  }
}
