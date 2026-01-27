import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspire_admin_portal/features/talks/domain/entities/event.dart';
import 'package:inspire_admin_portal/features/talks/presentation/providers/events_provider.dart';
import 'package:inspire_admin_portal/features/talks/presentation/providers/selected_event_provider.dart';
import 'package:inspire_admin_portal/features/talks/presentation/widgets/event_dropdown.dart';

void main() {
  group('EventDropdown', () {
    final testEvents = [
      const Event(id: 'event-1', name: 'Tech Conference 2024'),
      const Event(id: 'event-2', name: 'Developer Summit'),
      const Event(id: 'event-3'),
    ];

    testWidgets('should show loading indicator when loading', (tester) async {
      // Create a completer that we never complete to keep the loading state
      final completer = Completer<List<Event>>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventsProvider.overrideWith((ref) => completer.future),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: EventDropdown(),
              ),
            ),
          ),
        ),
      );

      // Pump once to build the widget in loading state
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show events dropdown when loaded', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventsProvider.overrideWith((ref) async => testEvents),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: EventDropdown(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(DropdownButton<Event>), findsOneWidget);
    });

    testWidgets('should show "Select an event" hint when no event selected', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventsProvider.overrideWith((ref) async => testEvents),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: EventDropdown(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Select an event'), findsOneWidget);
    });

    testWidgets('should show "No events found" when events list is empty', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventsProvider.overrideWith((ref) async => <Event>[]),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: EventDropdown(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No events found'), findsOneWidget);
    });

    testWidgets('should show error message on error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventsProvider.overrideWith((ref) async {
              throw Exception('Network error');
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: EventDropdown(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Error loading events'), findsOneWidget);
    });

    testWidgets('should display event name in dropdown items', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventsProvider.overrideWith((ref) async => testEvents),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: EventDropdown(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open dropdown
      await tester.tap(find.byType(DropdownButton<Event>));
      await tester.pumpAndSettle();

      expect(find.text('Tech Conference 2024'), findsWidgets);
      expect(find.text('Developer Summit'), findsWidgets);
    });

    testWidgets('should display event id when name is null', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventsProvider.overrideWith((ref) async => testEvents),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: EventDropdown(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open dropdown
      await tester.tap(find.byType(DropdownButton<Event>));
      await tester.pumpAndSettle();

      // event-3 has no name, should display id
      expect(find.text('event-3'), findsWidgets);
    });

    testWidgets('should select event when tapped', (tester) async {
      Event? selectedEvent;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventsProvider.overrideWith((ref) async => testEvents),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  selectedEvent = ref.watch(selectedEventProvider);
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: EventDropdown(),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open dropdown
      await tester.tap(find.byType(DropdownButton<Event>));
      await tester.pumpAndSettle();

      // Select an event
      await tester.tap(find.text('Tech Conference 2024').last);
      await tester.pumpAndSettle();

      expect(selectedEvent?.id, 'event-1');
      expect(selectedEvent?.name, 'Tech Conference 2024');
    });

    testWidgets('should show selected event name', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventsProvider.overrideWith((ref) async => testEvents),
            selectedEventProvider.overrideWith(() {
              return TestSelectedEventNotifier(testEvents.first);
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: EventDropdown(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // The selected event should be displayed
      expect(find.text('Tech Conference 2024'), findsOneWidget);
    });
  });
}

class TestSelectedEventNotifier extends SelectedEventNotifier {
  final Event? initialEvent;

  TestSelectedEventNotifier(this.initialEvent);

  @override
  Event? build() => initialEvent;
}
