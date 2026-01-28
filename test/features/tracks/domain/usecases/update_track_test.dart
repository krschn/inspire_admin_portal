import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:inspire_admin_portal/core/errors/failures.dart';
import 'package:inspire_admin_portal/features/tracks/domain/entities/track.dart';
import 'package:inspire_admin_portal/features/tracks/domain/repositories/track_repository.dart';
import 'package:inspire_admin_portal/features/tracks/domain/usecases/update_track.dart';
import 'package:mocktail/mocktail.dart';

class MockTrackRepository extends Mock implements TrackRepository {}

void main() {
  late UpdateTrack useCase;
  late MockTrackRepository mockRepository;

  setUp(() {
    mockRepository = MockTrackRepository();
    useCase = UpdateTrack(mockRepository);
  });

  const testTrack = Track(
    id: 'track-id',
    trackNumber: 1,
    trackDescription: 'Updated Track',
    trackColor: '#FF5733',
  );

  group('UpdateTrack', () {
    const eventId = 'event-123';

    test('should call repository.updateTrack with correct parameters', () async {
      when(
        () => mockRepository.updateTrack(eventId, testTrack),
      ).thenAnswer((_) async => const Right(testTrack));

      await useCase(eventId, testTrack);

      verify(() => mockRepository.updateTrack(eventId, testTrack)).called(1);
    });

    test('should return updated track on success', () async {
      when(
        () => mockRepository.updateTrack(eventId, testTrack),
      ).thenAnswer((_) async => const Right(testTrack));

      final result = await useCase(eventId, testTrack);

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected Right but got Left'),
        (track) {
          expect(track.id, 'track-id');
          expect(track.trackDescription, 'Updated Track');
          expect(track.trackColor, '#FF5733');
        },
      );
    });

    test('should return ServerFailure on server error', () async {
      when(
        () => mockRepository.updateTrack(eventId, testTrack),
      ).thenAnswer((_) async => const Left(ServerFailure('Failed to update')));

      final result = await useCase(eventId, testTrack);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'Failed to update');
        },
        (track) => fail('Expected Left but got Right'),
      );
    });

    test('should return NetworkFailure on network error', () async {
      when(
        () => mockRepository.updateTrack(eventId, testTrack),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final result = await useCase(eventId, testTrack);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (track) => fail('Expected Left but got Right'),
      );
    });
  });
}
