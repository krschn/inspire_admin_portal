import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:inspire_admin_portal/core/errors/failures.dart';
import 'package:inspire_admin_portal/features/tracks/domain/entities/track.dart';
import 'package:inspire_admin_portal/features/tracks/domain/repositories/track_repository.dart';
import 'package:inspire_admin_portal/features/tracks/domain/usecases/get_tracks.dart';
import 'package:mocktail/mocktail.dart';

class MockTrackRepository extends Mock implements TrackRepository {}

void main() {
  late GetTracks useCase;
  late MockTrackRepository mockRepository;

  setUp(() {
    mockRepository = MockTrackRepository();
    useCase = GetTracks(mockRepository);
  });

  const testTracks = [
    Track(
      id: 'track-1',
      trackNumber: 1,
      trackDescription: 'Track 1',
      trackColor: '#2E6CA4',
    ),
    Track(
      id: 'track-2',
      trackNumber: 2,
      trackDescription: 'Track 2',
      trackColor: '#4CAF50',
    ),
  ];

  group('GetTracks', () {
    const eventId = 'event-123';

    test('should call repository.getTracks with correct eventId', () async {
      when(
        () => mockRepository.getTracks(eventId),
      ).thenAnswer((_) async => const Right(testTracks));

      await useCase(eventId);

      verify(() => mockRepository.getTracks(eventId)).called(1);
    });

    test('should return list of tracks on success', () async {
      when(
        () => mockRepository.getTracks(eventId),
      ).thenAnswer((_) async => const Right(testTracks));

      final result = await useCase(eventId);

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected Right but got Left'),
        (tracks) {
          expect(tracks, equals(testTracks));
          expect(tracks.length, 2);
        },
      );
    });

    test('should return empty list when no tracks exist', () async {
      when(
        () => mockRepository.getTracks(eventId),
      ).thenAnswer((_) async => const Right([]));

      final result = await useCase(eventId);

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected Right but got Left'),
        (tracks) => expect(tracks, isEmpty),
      );
    });

    test('should return ServerFailure on server error', () async {
      when(
        () => mockRepository.getTracks(eventId),
      ).thenAnswer((_) async => const Left(ServerFailure('Server error')));

      final result = await useCase(eventId);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'Server error');
        },
        (tracks) => fail('Expected Left but got Right'),
      );
    });

    test('should return NetworkFailure on network error', () async {
      when(
        () => mockRepository.getTracks(eventId),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final result = await useCase(eventId);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (tracks) => fail('Expected Left but got Right'),
      );
    });
  });
}
