import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:inspire_admin_portal/core/errors/failures.dart';
import 'package:inspire_admin_portal/features/tracks/domain/entities/track.dart';
import 'package:inspire_admin_portal/features/tracks/domain/repositories/track_repository.dart';
import 'package:inspire_admin_portal/features/tracks/domain/usecases/batch_upload_tracks.dart';
import 'package:mocktail/mocktail.dart';

class MockTrackRepository extends Mock implements TrackRepository {}

void main() {
  late BatchUploadTracks useCase;
  late MockTrackRepository mockRepository;

  setUp(() {
    mockRepository = MockTrackRepository();
    useCase = BatchUploadTracks(mockRepository);
  });

  const testTracks = [
    Track(
      trackNumber: 1,
      trackDescription: 'Track 1',
      trackColor: '#2E6CA4',
    ),
    Track(
      trackNumber: 2,
      trackDescription: 'Track 2',
      trackColor: '#4CAF50',
    ),
    Track(
      trackNumber: 3,
      trackDescription: 'Track 3',
      trackColor: '#FF9800',
    ),
  ];

  group('BatchUploadTracks', () {
    const eventId = 'event-123';

    test('should call repository.batchUploadTracks with correct parameters', () async {
      when(
        () => mockRepository.batchUploadTracks(eventId, testTracks),
      ).thenAnswer(
        (_) async => const Right(
          TrackBatchUploadResult(
            createdCount: 3,
            updatedCount: 0,
            skippedRows: [],
          ),
        ),
      );

      await useCase(eventId, testTracks);

      verify(() => mockRepository.batchUploadTracks(eventId, testTracks)).called(1);
    });

    test('should return TrackBatchUploadResult on success with all created', () async {
      when(
        () => mockRepository.batchUploadTracks(eventId, testTracks),
      ).thenAnswer(
        (_) async => const Right(
          TrackBatchUploadResult(
            createdCount: 3,
            updatedCount: 0,
            skippedRows: [],
          ),
        ),
      );

      final result = await useCase(eventId, testTracks);

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected Right but got Left'),
        (uploadResult) {
          expect(uploadResult.createdCount, 3);
          expect(uploadResult.updatedCount, 0);
          expect(uploadResult.skippedRows, isEmpty);
        },
      );
    });

    test('should return TrackBatchUploadResult with mixed create/update counts', () async {
      when(
        () => mockRepository.batchUploadTracks(eventId, testTracks),
      ).thenAnswer(
        (_) async => const Right(
          TrackBatchUploadResult(
            createdCount: 1,
            updatedCount: 2,
            skippedRows: [],
          ),
        ),
      );

      final result = await useCase(eventId, testTracks);

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected Right but got Left'),
        (uploadResult) {
          expect(uploadResult.createdCount, 1);
          expect(uploadResult.updatedCount, 2);
        },
      );
    });

    test('should return TrackBatchUploadResult with skipped rows', () async {
      when(
        () => mockRepository.batchUploadTracks(eventId, testTracks),
      ).thenAnswer(
        (_) async => const Right(
          TrackBatchUploadResult(
            createdCount: 2,
            updatedCount: 0,
            skippedRows: [
              TrackSkippedRow(rowNumber: 3, reason: 'Duplicate track number'),
            ],
          ),
        ),
      );

      final result = await useCase(eventId, testTracks);

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected Right but got Left'),
        (uploadResult) {
          expect(uploadResult.createdCount, 2);
          expect(uploadResult.skippedRows.length, 1);
          expect(uploadResult.skippedRows.first.rowNumber, 3);
          expect(uploadResult.skippedRows.first.reason, 'Duplicate track number');
        },
      );
    });

    test('should return ServerFailure on server error', () async {
      when(
        () => mockRepository.batchUploadTracks(eventId, testTracks),
      ).thenAnswer((_) async => const Left(ServerFailure('Batch upload failed')));

      final result = await useCase(eventId, testTracks);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'Batch upload failed');
        },
        (_) => fail('Expected Left but got Right'),
      );
    });

    test('should return NetworkFailure on network error', () async {
      when(
        () => mockRepository.batchUploadTracks(eventId, testTracks),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final result = await useCase(eventId, testTracks);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Expected Left but got Right'),
      );
    });
  });
}
