import 'package:flutter_test/flutter_test.dart';
import 'package:inspire_admin_portal/features/tracks/domain/entities/track.dart';

void main() {
  group('Track', () {
    Track createTrack({
      String? id,
      int? trackNumber,
      String? trackDescription,
      String? trackColor,
    }) {
      return Track(
        id: id ?? 'test-id',
        trackNumber: trackNumber ?? 1,
        trackDescription: trackDescription ?? 'Test Track Description',
        trackColor: trackColor ?? '#2E6CA4',
      );
    }

    test('should create Track with all required fields', () {
      final track = createTrack();

      expect(track.id, 'test-id');
      expect(track.trackNumber, 1);
      expect(track.trackDescription, 'Test Track Description');
      expect(track.trackColor, '#2E6CA4');
    });

    test('should allow null id', () {
      final track = Track(
        trackNumber: 1,
        trackDescription: 'Description',
        trackColor: '#2E6CA4',
      );

      expect(track.id, isNull);
    });

    group('copyWith', () {
      test('should return a new Track with updated id', () {
        final track = createTrack();
        final updatedTrack = track.copyWith(id: 'new-id');

        expect(updatedTrack.id, 'new-id');
        expect(updatedTrack.trackNumber, track.trackNumber);
        expect(updatedTrack.trackDescription, track.trackDescription);
        expect(updatedTrack.trackColor, track.trackColor);
      });

      test('should return a new Track with updated trackNumber', () {
        final track = createTrack();
        final updatedTrack = track.copyWith(trackNumber: 5);

        expect(updatedTrack.trackNumber, 5);
        expect(updatedTrack.id, track.id);
      });

      test('should return a new Track with updated trackDescription', () {
        final track = createTrack();
        final updatedTrack = track.copyWith(trackDescription: 'New Description');

        expect(updatedTrack.trackDescription, 'New Description');
        expect(updatedTrack.id, track.id);
      });

      test('should return a new Track with updated trackColor', () {
        final track = createTrack();
        final updatedTrack = track.copyWith(trackColor: '#FF5733');

        expect(updatedTrack.trackColor, '#FF5733');
        expect(updatedTrack.id, track.id);
      });

      test('should return a new Track with all fields updated', () {
        final track = createTrack();
        final updatedTrack = track.copyWith(
          id: 'updated-id',
          trackNumber: 10,
          trackDescription: 'Updated Description',
          trackColor: '#123456',
        );

        expect(updatedTrack.id, 'updated-id');
        expect(updatedTrack.trackNumber, 10);
        expect(updatedTrack.trackDescription, 'Updated Description');
        expect(updatedTrack.trackColor, '#123456');
      });

      test('should keep original values when not specified in copyWith', () {
        final track = createTrack();
        final updatedTrack = track.copyWith();

        expect(updatedTrack.id, track.id);
        expect(updatedTrack.trackNumber, track.trackNumber);
        expect(updatedTrack.trackDescription, track.trackDescription);
        expect(updatedTrack.trackColor, track.trackColor);
      });
    });

    group('Equatable', () {
      test('should be equal when all properties are the same', () {
        final track1 = createTrack();
        final track2 = createTrack();

        expect(track1, equals(track2));
      });

      test('should not be equal when id is different', () {
        final track1 = createTrack(id: 'id-1');
        final track2 = createTrack(id: 'id-2');

        expect(track1, isNot(equals(track2)));
      });

      test('should not be equal when trackNumber is different', () {
        final track1 = createTrack(trackNumber: 1);
        final track2 = createTrack(trackNumber: 2);

        expect(track1, isNot(equals(track2)));
      });

      test('should not be equal when trackDescription is different', () {
        final track1 = createTrack(trackDescription: 'Desc 1');
        final track2 = createTrack(trackDescription: 'Desc 2');

        expect(track1, isNot(equals(track2)));
      });

      test('should not be equal when trackColor is different', () {
        final track1 = createTrack(trackColor: '#111111');
        final track2 = createTrack(trackColor: '#222222');

        expect(track1, isNot(equals(track2)));
      });

      test('should have same hashCode when equal', () {
        final track1 = createTrack();
        final track2 = createTrack();

        expect(track1.hashCode, equals(track2.hashCode));
      });

      test('props should include all properties', () {
        final track = createTrack();

        expect(track.props, [
          track.id,
          track.trackNumber,
          track.trackDescription,
          track.trackColor,
        ]);
      });
    });
  });
}
