import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:inspire_admin_portal/core/errors/failures.dart';
import 'package:inspire_admin_portal/features/talks/domain/entities/talk.dart';
import 'package:inspire_admin_portal/features/talks/domain/entities/speaker.dart';
import 'package:inspire_admin_portal/features/talks/domain/repositories/talk_repository.dart';
import 'package:inspire_admin_portal/features/talks/domain/usecases/update_talk.dart';

class MockTalkRepository extends Mock implements TalkRepository {}

void main() {
  late UpdateTalk useCase;
  late MockTalkRepository mockRepository;

  setUp(() {
    mockRepository = MockTalkRepository();
    useCase = UpdateTalk(mockRepository);
  });

  setUpAll(() {
    registerFallbackValue(Talk(
      date: DateTime.now(),
      title: '',
      description: '',
      speakers: const [],
      liveLink: '',
      duration: '',
      track: '',
      venue: '',
    ));
  });

  final testTalk = Talk(
    id: 'talk-123',
    date: DateTime(2024, 1, 15),
    title: 'Updated Talk',
    description: 'Updated Description',
    speakers: const [Speaker(name: 'Updated Speaker', image: 'https://example.com/updated.jpg')],
    liveLink: 'https://example.com/updated-live',
    duration: '45 min',
    track: 'Track B',
    venue: 'Room 202',
  );

  group('UpdateTalk', () {
    const eventId = 'event-123';

    test('should call repository.updateTalk with correct parameters', () async {
      when(() => mockRepository.updateTalk(eventId, testTalk))
          .thenAnswer((_) async => Right(testTalk));

      await useCase(eventId, testTalk);

      verify(() => mockRepository.updateTalk(eventId, testTalk)).called(1);
    });

    test('should return updated talk on success', () async {
      when(() => mockRepository.updateTalk(eventId, testTalk))
          .thenAnswer((_) async => Right(testTalk));

      final result = await useCase(eventId, testTalk);

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected Right but got Left'),
        (talk) {
          expect(talk.id, testTalk.id);
          expect(talk.title, 'Updated Talk');
          expect(talk.description, 'Updated Description');
        },
      );
    });

    test('should return ServerFailure on server error', () async {
      when(() => mockRepository.updateTalk(eventId, testTalk))
          .thenAnswer((_) async => const Left(ServerFailure('Failed to update')));

      final result = await useCase(eventId, testTalk);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'Failed to update');
        },
        (talk) => fail('Expected Left but got Right'),
      );
    });

    test('should return NetworkFailure on network error', () async {
      when(() => mockRepository.updateTalk(eventId, testTalk))
          .thenAnswer((_) async => const Left(NetworkFailure()));

      final result = await useCase(eventId, testTalk);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (talk) => fail('Expected Left but got Right'),
      );
    });
  });
}
