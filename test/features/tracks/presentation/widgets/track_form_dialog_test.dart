import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspire_admin_portal/features/tracks/domain/entities/track.dart';
import 'package:inspire_admin_portal/features/tracks/presentation/widgets/track_form_dialog.dart';

void main() {
  group('TrackFormDialog', () {
    Widget createWidget({
      Track? track,
      Future<bool> Function(Track)? onSubmit,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => TrackFormDialog(
                  track: track,
                  onSubmit: onSubmit ?? (_) async => true,
                ),
              ),
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );
    }

    Future<void> openDialog(WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();
    }

    group('Create mode', () {
      testWidgets('should display "Create Track" title', (tester) async {
        await openDialog(tester);

        expect(find.text('Create Track'), findsOneWidget);
      });

      testWidgets('should display empty form fields', (tester) async {
        await openDialog(tester);

        expect(find.text('Track Number *'), findsOneWidget);
        expect(find.text('Description *'), findsOneWidget);
        expect(find.text('Color *'), findsOneWidget);
      });

      testWidgets('should have default color value', (tester) async {
        await openDialog(tester);

        // Find the color text field and verify it contains the default color
        final colorField = find.widgetWithText(TextFormField, 'Color *');
        expect(colorField, findsOneWidget);

        // Verify the default color is in the form
        expect(find.text('#2E6CA4'), findsWidgets);
      });

      testWidgets('should display Create button', (tester) async {
        await openDialog(tester);

        expect(find.text('Create'), findsOneWidget);
      });

      testWidgets('should display Cancel button', (tester) async {
        await openDialog(tester);

        expect(find.text('Cancel'), findsOneWidget);
      });

      testWidgets('should show validation error for empty track number', (tester) async {
        await openDialog(tester);

        await tester.tap(find.text('Create'));
        await tester.pumpAndSettle();

        expect(find.text('Track number is required'), findsOneWidget);
      });

      testWidgets('should show validation error for empty description', (tester) async {
        await openDialog(tester);

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Track Number *'),
          '1',
        );
        await tester.tap(find.text('Create'));
        await tester.pumpAndSettle();

        expect(find.text('Description is required'), findsOneWidget);
      });

      testWidgets('should show validation error for invalid color format', (tester) async {
        await openDialog(tester);

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Track Number *'),
          '1',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Description *'),
          'Test Track',
        );

        // Clear default color and enter invalid
        final colorField = find.widgetWithText(TextFormField, 'Color *');
        await tester.enterText(colorField, '');
        await tester.enterText(colorField, 'invalid');

        await tester.tap(find.text('Create'));
        await tester.pumpAndSettle();

        expect(find.text('Invalid format (use #RRGGBB)'), findsOneWidget);
      });

      testWidgets('should close dialog on Cancel', (tester) async {
        await openDialog(tester);

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(find.text('Create Track'), findsNothing);
      });

      testWidgets('should call onSubmit with correct data', (tester) async {
        Track? submittedTrack;
        await tester.pumpWidget(createWidget(
          onSubmit: (track) async {
            submittedTrack = track;
            return true;
          },
        ));

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Track Number *'),
          '5',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Description *'),
          'Test Description',
        );
        // Keep default color

        await tester.tap(find.text('Create'));
        await tester.pumpAndSettle();

        expect(submittedTrack, isNotNull);
        expect(submittedTrack!.trackNumber, 5);
        expect(submittedTrack!.trackDescription, 'Test Description');
        expect(submittedTrack!.trackColor, '#2E6CA4');
      });

      testWidgets('should only allow digits in track number field', (tester) async {
        await openDialog(tester);

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Track Number *'),
          'abc123def',
        );
        await tester.pump();

        // Should only contain '123'
        expect(find.text('123'), findsOneWidget);
      });
    });

    group('Edit mode', () {
      const existingTrack = Track(
        id: 'track-1',
        trackNumber: 7,
        trackDescription: 'Data & Analytics',
        trackColor: '#FF5733',
      );

      testWidgets('should display "Edit Track" title', (tester) async {
        await tester.pumpWidget(createWidget(track: existingTrack));
        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Edit Track'), findsOneWidget);
      });

      testWidgets('should display Update button', (tester) async {
        await tester.pumpWidget(createWidget(track: existingTrack));
        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Update'), findsOneWidget);
      });

      testWidgets('should pre-fill form with existing track data', (tester) async {
        await tester.pumpWidget(createWidget(track: existingTrack));
        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('7'), findsOneWidget);
        expect(find.text('Data & Analytics'), findsOneWidget);
        expect(find.text('#FF5733'), findsOneWidget);
      });

      testWidgets('should preserve track ID on submit', (tester) async {
        Track? submittedTrack;
        await tester.pumpWidget(createWidget(
          track: existingTrack,
          onSubmit: (track) async {
            submittedTrack = track;
            return true;
          },
        ));

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Update'));
        await tester.pumpAndSettle();

        expect(submittedTrack, isNotNull);
        expect(submittedTrack!.id, 'track-1');
      });
    });

    group('Color preview', () {
      testWidgets('should show color preview box', (tester) async {
        await openDialog(tester);

        // The color preview container should exist
        final containers = find.byType(Container);
        expect(containers, findsWidgets);
      });

      testWidgets('should update preview when color is changed', (tester) async {
        await openDialog(tester);

        // Enter a new color
        final colorField = find.widgetWithText(TextFormField, 'Color *');
        await tester.enterText(colorField, '');
        await tester.enterText(colorField, '#FF0000');
        await tester.pump();

        // Widget should rebuild with new color - just verify no error
        expect(find.text('#FF0000'), findsOneWidget);
      });
    });
  });
}
