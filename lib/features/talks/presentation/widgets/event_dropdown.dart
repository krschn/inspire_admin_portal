import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/event.dart';
import '../providers/events_provider.dart';
import '../providers/selected_event_provider.dart';

class EventDropdown extends ConsumerWidget {
  const EventDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);
    final selectedEvent = ref.watch(selectedEventProvider);

    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return const Text('No events found');
        }

        return DropdownButton<Event>(
          value: selectedEvent,
          hint: const Text('Select an event'),
          isExpanded: true,
          items: events.map((event) {
            return DropdownMenuItem<Event>(
              value: event,
              child: Text(event.name ?? event.id),
            );
          }).toList(),
          onChanged: (event) {
            ref.read(selectedEventProvider.notifier).select(event);
          },
        );
      },
      loading: () => const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Text(
        'Error loading events: $error',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
