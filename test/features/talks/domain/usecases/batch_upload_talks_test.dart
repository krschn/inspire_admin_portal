import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:inspire_admin_portal/core/errors/failures.dart';
import 'package:inspire_admin_portal/features/talks/domain/entities/speaker.dart';
import 'package:inspire_admin_portal/features/talks/domain/entities/talk.dart';
import 'package:inspire_admin_portal/features/talks/domain/repositories/talk_repository.dart';
import 'package:inspire_admin_portal/features/talks/domain/usecases/batch_upload_talks.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  late BatchUploadTalks useCase;
  late MockTalkRepository mockRepository;

  setUp(() {
    mockRepository = MockTalkRepository();
    useCase = BatchUploadTalks(mockRepository);
  });

  setUpAll(() {
    registerFallbackValue(<Talk>[]);
  });

  final testTalks = [
    Talk(
      date: DateTime(2024, 1, 15),
      title: 'Talk 1',
      description: 'Description 1',
      speakers: const [Speaker(name: 'Speaker 1', image: '')],
      liveLink: '',
      duration: '30 min',
      track: 1,
      venue: 'Room 101',
    ),
    Talk(
      date: DateTime(2024, 1, 16),
      title: 'Talk 2',
      description: 'Description 2',
      speakers: const [],
      liveLink: '',
      duration: '45 min',
      track: 1,
      venue: 'Room 102',
    ),
  ];

  group('BatchUploadTalks', () {
    const eventId = 'event-123';

    test(
      'should call repository.batchUploadTalks with correct parameters',
      () async {
        when(
          () => mockRepository.batchUploadTalks(eventId, testTalks),
        ).thenAnswer(
          (_) async => const Right(
            BatchUploadResult(
              createdCount: 2,
              updatedCount: 0,
              skippedRows: [],
            ),
          ),
        );

        await useCase(eventId, testTalks);

        verify(
          () => mockRepository.batchUploadTalks(eventId, testTalks),
        ).called(1);
      },
    );

    test(
      'should return BatchUploadResult with created counts on success',
      () async {
        when(
          () => mockRepository.batchUploadTalks(eventId, testTalks),
        ).thenAnswer(
          (_) async => const Right(
            BatchUploadResult(
              createdCount: 2,
              updatedCount: 0,
              skippedRows: [],
            ),
          ),
        );

        final result = await useCase(eventId, testTalks);

        expect(result.isRight(), isTrue);
        result.fold((failure) => fail('Expected Right but got Left'), (
          uploadResult,
        ) {
          expect(uploadResult.createdCount, 2);
          expect(uploadResult.updatedCount, 0);
          expect(uploadResult.skippedRows, isEmpty);
        });
      },
    );

    test('should return BatchUploadResult with updated counts', () async {
      when(
        () => mockRepository.batchUploadTalks(eventId, testTalks),
      ).thenAnswer(
        (_) async => const Right(
          BatchUploadResult(createdCount: 0, updatedCount: 2, skippedRows: []),
        ),
      );

      final result = await useCase(eventId, testTalks);

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Expected Right but got Left'), (
        uploadResult,
      ) {
        expect(uploadResult.createdCount, 0);
        expect(uploadResult.updatedCount, 2);
      });
    });

    test('should return BatchUploadResult with skipped rows', () async {
      when(
        () => mockRepository.batchUploadTalks(eventId, testTalks),
      ).thenAnswer(
        (_) async => const Right(
          BatchUploadResult(
            createdCount: 1,
            updatedCount: 0,
            skippedRows: [SkippedRow(rowNumber: 3, reason: 'Invalid data')],
          ),
        ),
      );

      final result = await useCase(eventId, testTalks);

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Expected Right but got Left'), (
        uploadResult,
      ) {
        expect(uploadResult.createdCount, 1);
        expect(uploadResult.skippedRows.length, 1);
        expect(uploadResult.skippedRows.first.rowNumber, 3);
        expect(uploadResult.skippedRows.first.reason, 'Invalid data');
      });
    });

    test('should return ServerFailure on server error', () async {
      when(
        () => mockRepository.batchUploadTalks(eventId, testTalks),
      ).thenAnswer((_) async => const Left(ServerFailure('Upload failed')));

      final result = await useCase(eventId, testTalks);

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, 'Upload failed');
      }, (_) => fail('Expected Left but got Right'));
    });

    test('should return NetworkFailure on network error', () async {
      when(
        () => mockRepository.batchUploadTalks(eventId, testTalks),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final result = await useCase(eventId, testTalks);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Expected Left but got Right'),
      );
    });

    test('should handle empty talks list', () async {
      when(() => mockRepository.batchUploadTalks(eventId, any())).thenAnswer(
        (_) async => const Right(
          BatchUploadResult(createdCount: 0, updatedCount: 0, skippedRows: []),
        ),
      );

      final result = await useCase(eventId, []);

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Expected Right but got Left'), (
        uploadResult,
      ) {
        expect(uploadResult.createdCount, 0);
        expect(uploadResult.updatedCount, 0);
      });
    });
  });
}

class MockTalkRepository extends Mock implements TalkRepository {}
