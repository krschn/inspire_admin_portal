import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:inspire_admin_portal/core/errors/failures.dart';
import 'package:inspire_admin_portal/features/tracks/domain/entities/track.dart';
import 'package:inspire_admin_portal/features/tracks/domain/repositories/track_repository.dart';
import 'package:inspire_admin_portal/features/tracks/domain/usecases/create_track.dart';
import 'package:mocktail/mocktail.dart';

class MockTrackRepository extends Mock implements TrackRepository {}

void main() {
  late CreateTrack useCase;
  late MockTrackRepository mockRepository;

  setUp(() {
    mockRepository = MockTrackRepository();
    useCase = CreateTrack(mockRepository);
  });

  const testTrack = Track(
    trackNumber: 1,
    trackDescription: 'Test Track',
    trackColor: '#2E6CA4',
  );

  const createdTrack = Track(
    id: 'created-id',
    trackNumber: 1,
    trackDescription: 'Test Track',
    trackColor: '#2E6CA4',
  );

  group('CreateTrack', () {
    const eventId = 'event-123';

    test('should call repository.createTrack with correct parameters', () async {
      when(
        () => mockRepository.createTrack(eventId, testTrack),
      ).thenAnswer((_) async => const Right(createdTrack));

      await useCase(eventId, testTrack);

      verify(() => mockRepository.createTrack(eventId, testTrack)).called(1);
    });

    test('should return created track on success', () async {
      when(
        () => mockRepository.createTrack(eventId, testTrack),
      ).thenAnswer((_) async => const Right(createdTrack));

      final result = await useCase(eventId, testTrack);

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected Right but got Left'),
        (track) {
          expect(track.id, 'created-id');
          expect(track.trackNumber, 1);
          expect(track.trackDescription, 'Test Track');
        },
      );
    });

    test('should return ServerFailure on server error', () async {
      when(
        () => mockRepository.createTrack(eventId, testTrack),
      ).thenAnswer((_) async => const Left(ServerFailure('Failed to create')));

      final result = await useCase(eventId, testTrack);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'Failed to create');
        },
        (track) => fail('Expected Left but got Right'),
      );
    });

    test('should return NetworkFailure on network error', () async {
      when(
        () => mockRepository.createTrack(eventId, testTrack),
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
