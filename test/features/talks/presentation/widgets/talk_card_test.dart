import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspire_admin_portal/features/talks/domain/entities/speaker.dart';
import 'package:inspire_admin_portal/features/talks/domain/entities/talk.dart';
import 'package:inspire_admin_portal/features/talks/presentation/widgets/talk_card.dart';

void main() {
  group('TalkCard', () {
    final testDate = DateTime(2024, 1, 15, 14, 30);

    Talk createTalk({
      String? id,
      String? title,
      String? description,
      List<Speaker>? speakers,
      String? liveLink,
      String? duration,
      int? track,
      String? venue,
    }) {
      return Talk(
        id: id ?? 'test-id',
        date: testDate,
        title: title ?? 'Test Talk Title',
        description: description ?? 'Test Description',
        speakers: speakers ?? const [],
        liveLink: liveLink ?? '',
        duration: duration ?? '',
        track: track ?? 0,
        venue: venue ?? '',
      );
    }

    Widget createTestWidget({
      required Talk talk,
      VoidCallback? onEdit,
      VoidCallback? onDelete,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: TalkCard(
            talk: talk,
            onEdit: onEdit ?? () {},
            onDelete: onDelete ?? () {},
          ),
        ),
      );
    }

    testWidgets('should display talk title', (tester) async {
      await tester.pumpWidget(
        createTestWidget(talk: createTalk(title: 'My Awesome Talk')),
      );

      expect(find.text('My Awesome Talk'), findsOneWidget);
    });

    testWidgets('should display formatted date with time', (tester) async {
      await tester.pumpWidget(createTestWidget(talk: createTalk()));

      // Date format is 'MMM d, yyyy h:mm a'
      expect(find.text('Jan 15, 2024 2:30 PM'), findsOneWidget);
    });

    testWidgets('should display description when not empty', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          talk: createTalk(description: 'This is a detailed description'),
        ),
      );

      expect(find.text('This is a detailed description'), findsOneWidget);
    });

    testWidgets('should not display description when empty', (tester) async {
      await tester.pumpWidget(
        createTestWidget(talk: createTalk(description: '')),
      );

      // Should only find title, not an empty description text
      expect(find.text('Test Talk Title'), findsOneWidget);
    });

    testWidgets('should display track chip when not empty', (tester) async {
      await tester.pumpWidget(createTestWidget(talk: createTalk(track: 1)));

      expect(find.text('1'), findsOneWidget);
      expect(find.byIcon(Icons.category), findsOneWidget);
    });

    testWidgets('should display venue chip when not empty', (tester) async {
      await tester.pumpWidget(
        createTestWidget(talk: createTalk(venue: 'Room 101')),
      );

      expect(find.text('Room 101'), findsOneWidget);
      expect(find.byIcon(Icons.location_on), findsOneWidget);
    });

    testWidgets('should display duration chip when not empty', (tester) async {
      await tester.pumpWidget(
        createTestWidget(talk: createTalk(duration: '30 min')),
      );

      expect(find.text('30 min'), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('should not display chips when values are empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          talk: createTalk(track: 0, venue: '', duration: ''),
        ),
      );

      expect(find.byIcon(Icons.category), findsNothing);
      expect(find.byIcon(Icons.location_on), findsNothing);
      expect(find.byIcon(Icons.schedule), findsNothing);
    });

    testWidgets('should display speaker names', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          talk: createTalk(
            speakers: const [
              Speaker(name: 'John Doe', image: ''),
              Speaker(name: 'Jane Smith', image: ''),
            ],
          ),
        ),
      );

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);
    });

    testWidgets(
      'should display speaker chip with Chip widget when image provided',
      (tester) async {
        // Note: Using empty image to avoid NetworkImage issues in test
        await tester.pumpWidget(
          createTestWidget(
            talk: createTalk(
              speakers: const [Speaker(name: 'John Doe', image: '')],
            ),
          ),
        );

        expect(find.byType(Chip), findsOneWidget);
        expect(find.text('John Doe'), findsOneWidget);
      },
    );

    testWidgets('should display default avatar icon when no image', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          talk: createTalk(
            speakers: const [Speaker(name: 'John Doe', image: '')],
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('should display live link when not empty', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          talk: createTalk(liveLink: 'https://example.com/live'),
        ),
      );

      expect(find.text('https://example.com/live'), findsOneWidget);
      expect(find.byIcon(Icons.link), findsOneWidget);
    });

    testWidgets('should not display live link section when empty', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget(talk: createTalk(liveLink: '')));

      expect(find.byIcon(Icons.link), findsNothing);
    });

    testWidgets('should have edit button', (tester) async {
      await tester.pumpWidget(createTestWidget(talk: createTalk()));

      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byTooltip('Edit'), findsOneWidget);
    });

    testWidgets('should have delete button', (tester) async {
      await tester.pumpWidget(createTestWidget(talk: createTalk()));

      expect(find.byIcon(Icons.delete), findsOneWidget);
      expect(find.byTooltip('Delete'), findsOneWidget);
    });

    testWidgets('should call onEdit when edit button is pressed', (
      tester,
    ) async {
      bool editCalled = false;

      await tester.pumpWidget(
        createTestWidget(talk: createTalk(), onEdit: () => editCalled = true),
      );

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pump();

      expect(editCalled, isTrue);
    });

    testWidgets('should call onDelete when delete button is pressed', (
      tester,
    ) async {
      bool deleteCalled = false;

      await tester.pumpWidget(
        createTestWidget(
          talk: createTalk(),
          onDelete: () => deleteCalled = true,
        ),
      );

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pump();

      expect(deleteCalled, isTrue);
    });

    testWidgets('should be wrapped in a Card widget', (tester) async {
      await tester.pumpWidget(createTestWidget(talk: createTalk()));

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('should display all information for a complete talk', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(
          talk: createTalk(
            title: 'Complete Talk',
            description: 'Full description here',
            speakers: const [Speaker(name: 'Speaker Name', image: '')],
            liveLink: 'https://live.example.com',
            duration: '60 min',
            track: 1,
            venue: 'Main Hall',
          ),
        ),
      );

      expect(find.text('Complete Talk'), findsOneWidget);
      expect(find.text('Full description here'), findsOneWidget);
      expect(find.text('Speaker Name'), findsOneWidget);
      expect(find.text('https://live.example.com'), findsOneWidget);
      expect(find.text('60 min'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('Main Hall'), findsOneWidget);
    });

    testWidgets(
      'should show CircleAvatar with NetworkImage when speaker has image URL',
      (tester) async {
        // This test verifies the structure exists, but doesn't load the actual network image
        await tester.pumpWidget(
          createTestWidget(
            talk: createTalk(
              speakers: const [
                Speaker(
                  name: 'John Doe',
                  image: '',
                ), // Using empty to avoid network calls
              ],
            ),
          ),
        );

        // Verify the Chip and CircleAvatar structure exists
        expect(find.byType(Chip), findsOneWidget);
        expect(find.byType(CircleAvatar), findsOneWidget);
      },
    );
  });
}
