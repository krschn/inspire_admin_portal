import 'package:flutter_test/flutter_test.dart';
import 'package:inspire_admin_portal/core/errors/exceptions.dart';
import 'package:inspire_admin_portal/core/errors/failures.dart';
import 'package:inspire_admin_portal/features/talks/data/datasources/talk_remote_datasource.dart';
import 'package:inspire_admin_portal/features/talks/data/models/event_model.dart';
import 'package:inspire_admin_portal/features/talks/data/models/talk_model.dart';
import 'package:inspire_admin_portal/features/talks/data/repositories/talk_repository_impl.dart';
import 'package:inspire_admin_portal/features/talks/domain/entities/speaker.dart';
import 'package:inspire_admin_portal/features/talks/domain/entities/talk.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  late TalkRepositoryImpl repository;
  late MockTalkRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockTalkRemoteDataSource();
    repository = TalkRepositoryImpl(mockDataSource);
  });

  setUpAll(() {
    registerFallbackValue(
      TalkModel(
        date: DateTime.now(),
        title: '',
        description: '',
        speakers: const [],
        liveLink: '',
        duration: '',
        track: 0,
        venue: '',
      ),
    );
  });

  final testDate = DateTime(2024, 1, 15);

  final testTalkModels = [
    TalkModel(
      id: 'talk-1',
      date: testDate,
      title: 'Talk 1',
      description: 'Description 1',
      speakers: const [Speaker(name: 'Speaker 1', image: '')],
      liveLink: '',
      duration: '30 min',
      track: 1,
      venue: 'Room 101',
    ),
    TalkModel(
      id: 'talk-2',
      date: testDate.add(const Duration(days: 1)),
      title: 'Talk 2',
      description: 'Description 2',
      speakers: const [],
      liveLink: '',
      duration: '45 min',
      track: 1,
      venue: 'Room 102',
    ),
  ];

  final testEventModels = [
    const EventModel(id: 'event-1', name: 'Event 1'),
    const EventModel(id: 'event-2', name: 'Event 2'),
  ];

  group('TalkRepositoryImpl', () {
    group('getEvents', () {
      test('should return list of events on success', () async {
        when(
          () => mockDataSource.getEvents(),
        ).thenAnswer((_) async => testEventModels);

        final result = await repository.getEvents();

        expect(result.isRight(), isTrue);
        result.fold((failure) => fail('Expected Right but got Left'), (events) {
          expect(events.length, 2);
          expect(events[0].id, 'event-1');
          expect(events[0].name, 'Event 1');
        });
        verify(() => mockDataSource.getEvents()).called(1);
      });

      test('should return NetworkFailure on NetworkException', () async {
        when(
          () => mockDataSource.getEvents(),
        ).thenThrow(const NetworkException());

        final result = await repository.getEvents();

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<NetworkFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      });

      test('should return ServerFailure on ServerException', () async {
        when(
          () => mockDataSource.getEvents(),
        ).thenThrow(const ServerException('Server error'));

        final result = await repository.getEvents();

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'Server error');
        }, (_) => fail('Expected Left but got Right'));
      });
    });

    group('getTalks', () {
      const eventId = 'event-123';

      test('should return list of talks on success', () async {
        when(
          () => mockDataSource.getTalks(eventId),
        ).thenAnswer((_) async => testTalkModels);

        final result = await repository.getTalks(eventId);

        expect(result.isRight(), isTrue);
        result.fold((failure) => fail('Expected Right but got Left'), (talks) {
          expect(talks.length, 2);
          expect(talks[0].id, 'talk-1');
          expect(talks[0].title, 'Talk 1');
        });
        verify(() => mockDataSource.getTalks(eventId)).called(1);
      });

      test('should return NetworkFailure on NetworkException', () async {
        when(
          () => mockDataSource.getTalks(eventId),
        ).thenThrow(const NetworkException());

        final result = await repository.getTalks(eventId);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<NetworkFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      });

      test('should return ServerFailure on ServerException', () async {
        when(
          () => mockDataSource.getTalks(eventId),
        ).thenThrow(const ServerException('Failed to fetch talks'));

        final result = await repository.getTalks(eventId);

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'Failed to fetch talks');
        }, (_) => fail('Expected Left but got Right'));
      });
    });

    group('createTalk', () {
      const eventId = 'event-123';

      final inputTalk = Talk(
        date: testDate,
        title: 'New Talk',
        description: 'New Description',
        speakers: const [Speaker(name: 'New Speaker', image: '')],
        liveLink: 'https://example.com',
        duration: '30 min',
        track: 1,
        venue: 'Room 101',
      );

      final createdTalkModel = TalkModel(
        id: 'created-id',
        date: testDate,
        title: 'New Talk',
        description: 'New Description',
        speakers: const [Speaker(name: 'New Speaker', image: '')],
        liveLink: 'https://example.com',
        duration: '30 min',
        track: 1,
        venue: 'Room 101',
      );

      test('should return created talk on success', () async {
        when(
          () => mockDataSource.createTalk(eventId, any()),
        ).thenAnswer((_) async => createdTalkModel);

        final result = await repository.createTalk(eventId, inputTalk);

        expect(result.isRight(), isTrue);
        result.fold((failure) => fail('Expected Right but got Left'), (talk) {
          expect(talk.id, 'created-id');
          expect(talk.title, 'New Talk');
        });
        verify(() => mockDataSource.createTalk(eventId, any())).called(1);
      });

      test('should return NetworkFailure on NetworkException', () async {
        when(
          () => mockDataSource.createTalk(eventId, any()),
        ).thenThrow(const NetworkException());

        final result = await repository.createTalk(eventId, inputTalk);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<NetworkFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      });

      test('should return ServerFailure on ServerException', () async {
        when(
          () => mockDataSource.createTalk(eventId, any()),
        ).thenThrow(const ServerException('Failed to create'));

        final result = await repository.createTalk(eventId, inputTalk);

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'Failed to create');
        }, (_) => fail('Expected Left but got Right'));
      });
    });

    group('updateTalk', () {
      const eventId = 'event-123';

      final inputTalk = Talk(
        id: 'talk-123',
        date: testDate,
        title: 'Updated Talk',
        description: 'Updated Description',
        speakers: const [],
        liveLink: '',
        duration: '45 min',
        track: 1,
        venue: 'Room 202',
      );

      final updatedTalkModel = TalkModel(
        id: 'talk-123',
        date: testDate,
        title: 'Updated Talk',
        description: 'Updated Description',
        speakers: const [],
        liveLink: '',
        duration: '45 min',
        track: 1,
        venue: 'Room 202',
      );

      test('should return updated talk on success', () async {
        when(
          () => mockDataSource.updateTalk(eventId, any()),
        ).thenAnswer((_) async => updatedTalkModel);

        final result = await repository.updateTalk(eventId, inputTalk);

        expect(result.isRight(), isTrue);
        result.fold((failure) => fail('Expected Right but got Left'), (talk) {
          expect(talk.id, 'talk-123');
          expect(talk.title, 'Updated Talk');
        });
        verify(() => mockDataSource.updateTalk(eventId, any())).called(1);
      });

      test('should return NetworkFailure on NetworkException', () async {
        when(
          () => mockDataSource.updateTalk(eventId, any()),
        ).thenThrow(const NetworkException());

        final result = await repository.updateTalk(eventId, inputTalk);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<NetworkFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      });

      test('should return ServerFailure on ServerException', () async {
        when(
          () => mockDataSource.updateTalk(eventId, any()),
        ).thenThrow(const ServerException('Failed to update'));

        final result = await repository.updateTalk(eventId, inputTalk);

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'Failed to update');
        }, (_) => fail('Expected Left but got Right'));
      });
    });

    group('deleteTalk', () {
      const eventId = 'event-123';
      const talkId = 'talk-456';

      test('should return Right(null) on success', () async {
        when(
          () => mockDataSource.deleteTalk(eventId, talkId),
        ).thenAnswer((_) async {});

        final result = await repository.deleteTalk(eventId, talkId);

        expect(result.isRight(), isTrue);
        verify(() => mockDataSource.deleteTalk(eventId, talkId)).called(1);
      });

      test('should return NetworkFailure on NetworkException', () async {
        when(
          () => mockDataSource.deleteTalk(eventId, talkId),
        ).thenThrow(const NetworkException());

        final result = await repository.deleteTalk(eventId, talkId);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<NetworkFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      });

      test('should return ServerFailure on ServerException', () async {
        when(
          () => mockDataSource.deleteTalk(eventId, talkId),
        ).thenThrow(const ServerException('Failed to delete'));

        final result = await repository.deleteTalk(eventId, talkId);

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'Failed to delete');
        }, (_) => fail('Expected Left but got Right'));
      });
    });

    group('batchUploadTalks', () {
      const eventId = 'event-123';

      final inputTalks = [
        Talk(
          date: testDate,
          title: 'Talk 1',
          description: 'Desc 1',
          speakers: const [],
          liveLink: '',
          duration: '30 min',
          track: 1,
          venue: 'Room 101',
        ),
        Talk(
          date: testDate.add(const Duration(days: 1)),
          title: 'Talk 2',
          description: 'Desc 2',
          speakers: const [],
          liveLink: '',
          duration: '45 min',
          track: 1,
          venue: 'Room 102',
        ),
      ];

      test('should create new talks when they do not exist', () async {
        when(
          () => mockDataSource.findTalkByTitleAndDate(eventId, any(), any()),
        ).thenAnswer((_) async => null);
        when(
          () => mockDataSource.createTalk(eventId, any()),
        ).thenAnswer((_) async => testTalkModels[0]);

        final result = await repository.batchUploadTalks(eventId, inputTalks);

        expect(result.isRight(), isTrue);
        result.fold((failure) => fail('Expected Right but got Left'), (
          uploadResult,
        ) {
          expect(uploadResult.createdCount, 2);
          expect(uploadResult.updatedCount, 0);
          expect(uploadResult.skippedRows, isEmpty);
        });
        verify(() => mockDataSource.createTalk(eventId, any())).called(2);
      });

      test('should update talks when they already exist', () async {
        when(
          () => mockDataSource.findTalkByTitleAndDate(eventId, any(), any()),
        ).thenAnswer((_) async => testTalkModels[0]);
        when(
          () => mockDataSource.updateTalk(eventId, any()),
        ).thenAnswer((_) async => testTalkModels[0]);

        final result = await repository.batchUploadTalks(eventId, inputTalks);

        expect(result.isRight(), isTrue);
        result.fold((failure) => fail('Expected Right but got Left'), (
          uploadResult,
        ) {
          expect(uploadResult.createdCount, 0);
          expect(uploadResult.updatedCount, 2);
          expect(uploadResult.skippedRows, isEmpty);
        });
        verify(() => mockDataSource.updateTalk(eventId, any())).called(2);
      });

      test('should skip rows with ServerException and continue', () async {
        when(
          () => mockDataSource.findTalkByTitleAndDate(eventId, 'Talk 1', any()),
        ).thenThrow(const ServerException('Error finding talk'));
        when(
          () => mockDataSource.findTalkByTitleAndDate(eventId, 'Talk 2', any()),
        ).thenAnswer((_) async => null);
        when(
          () => mockDataSource.createTalk(eventId, any()),
        ).thenAnswer((_) async => testTalkModels[1]);

        final result = await repository.batchUploadTalks(eventId, inputTalks);

        expect(result.isRight(), isTrue);
        result.fold((failure) => fail('Expected Right but got Left'), (
          uploadResult,
        ) {
          expect(uploadResult.createdCount, 1);
          expect(uploadResult.skippedRows.length, 1);
          expect(uploadResult.skippedRows.first.rowNumber, 2);
          expect(uploadResult.skippedRows.first.reason, 'Error finding talk');
        });
      });

      test('should return NetworkFailure when network error occurs', () async {
        when(
          () => mockDataSource.findTalkByTitleAndDate(eventId, any(), any()),
        ).thenThrow(const NetworkException());

        final result = await repository.batchUploadTalks(eventId, inputTalks);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<NetworkFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      });

      test('should handle empty talks list', () async {
        final result = await repository.batchUploadTalks(eventId, []);

        expect(result.isRight(), isTrue);
        result.fold((failure) => fail('Expected Right but got Left'), (
          uploadResult,
        ) {
          expect(uploadResult.createdCount, 0);
          expect(uploadResult.updatedCount, 0);
          expect(uploadResult.skippedRows, isEmpty);
        });
      });
    });
  });
}

class MockTalkRemoteDataSource extends Mock implements TalkRemoteDataSource {}
