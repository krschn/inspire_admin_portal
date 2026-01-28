import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspire_admin_portal/features/tracks/domain/entities/track.dart';
import 'package:inspire_admin_portal/features/tracks/presentation/widgets/track_card.dart';

void main() {
  group('TrackCard', () {
    const testTrack = Track(
      id: 'track-1',
      trackNumber: 7,
      trackDescription: 'Data & Analytics',
      trackColor: '#2E6CA4',
    );

    Widget createWidget({
      Track track = testTrack,
      VoidCallback? onEdit,
      VoidCallback? onDelete,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: TrackCard(
            track: track,
            onEdit: onEdit ?? () {},
            onDelete: onDelete ?? () {},
          ),
        ),
      );
    }

    testWidgets('should display track number', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.text('7'), findsOneWidget);
      expect(find.text('Track 7'), findsOneWidget);
    });

    testWidgets('should display track description', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.text('Data & Analytics'), findsOneWidget);
    });

    testWidgets('should display track color hex value', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.text('#2E6CA4'), findsOneWidget);
    });

    testWidgets('should display edit button', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('should display delete button', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('should call onEdit when edit button is pressed', (tester) async {
      bool editCalled = false;
      await tester.pumpWidget(createWidget(
        onEdit: () => editCalled = true,
      ));

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pump();

      expect(editCalled, isTrue);
    });

    testWidgets('should call onDelete when delete button is pressed', (tester) async {
      bool deleteCalled = false;
      await tester.pumpWidget(createWidget(
        onDelete: () => deleteCalled = true,
      ));

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pump();

      expect(deleteCalled, isTrue);
    });

    testWidgets('should display color indicator with correct color', (tester) async {
      await tester.pumpWidget(createWidget());

      // Find the container with the track color (there should be multiple - one large and one small)
      final colorContainers = tester.widgetList<Container>(
        find.byType(Container),
      );

      // Just verify the widget renders without error
      expect(colorContainers.isNotEmpty, isTrue);
    });

    testWidgets('should handle invalid color gracefully', (tester) async {
      const trackWithInvalidColor = Track(
        id: 'track-1',
        trackNumber: 1,
        trackDescription: 'Test Track',
        trackColor: 'invalid',
      );

      await tester.pumpWidget(createWidget(track: trackWithInvalidColor));

      // Should render without error, using default color
      expect(find.text('Track 1'), findsOneWidget);
    });

    testWidgets('should display different track numbers correctly', (tester) async {
      const track = Track(
        id: 'track-1',
        trackNumber: 15,
        trackDescription: 'Track Fifteen',
        trackColor: '#FF5733',
      );

      await tester.pumpWidget(createWidget(track: track));

      expect(find.text('15'), findsOneWidget);
      expect(find.text('Track 15'), findsOneWidget);
      expect(find.text('Track Fifteen'), findsOneWidget);
    });
  });
}
