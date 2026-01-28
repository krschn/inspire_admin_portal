import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:inspire_admin_portal/core/errors/failures.dart';
import 'package:inspire_admin_portal/features/tracks/domain/repositories/track_repository.dart';
import 'package:inspire_admin_portal/features/tracks/domain/usecases/delete_track.dart';
import 'package:mocktail/mocktail.dart';

class MockTrackRepository extends Mock implements TrackRepository {}

void main() {
  late DeleteTrack useCase;
  late MockTrackRepository mockRepository;

  setUp(() {
    mockRepository = MockTrackRepository();
    useCase = DeleteTrack(mockRepository);
  });

  group('DeleteTrack', () {
    const eventId = 'event-123';
    const trackId = 'track-456';

    test('should call repository.deleteTrack with correct parameters', () async {
      when(
        () => mockRepository.deleteTrack(eventId, trackId),
      ).thenAnswer((_) async => const Right(null));

      await useCase(eventId, trackId);

      verify(() => mockRepository.deleteTrack(eventId, trackId)).called(1);
    });

    test('should return Right(void) on success', () async {
      when(
        () => mockRepository.deleteTrack(eventId, trackId),
      ).thenAnswer((_) async => const Right(null));

      final result = await useCase(eventId, trackId);

      expect(result.isRight(), isTrue);
    });

    test('should return ServerFailure on server error', () async {
      when(
        () => mockRepository.deleteTrack(eventId, trackId),
      ).thenAnswer((_) async => const Left(ServerFailure('Failed to delete')));

      final result = await useCase(eventId, trackId);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'Failed to delete');
        },
        (_) => fail('Expected Left but got Right'),
      );
    });

    test('should return NetworkFailure on network error', () async {
      when(
        () => mockRepository.deleteTrack(eventId, trackId),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final result = await useCase(eventId, trackId);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Expected Left but got Right'),
      );
    });
  });
}
