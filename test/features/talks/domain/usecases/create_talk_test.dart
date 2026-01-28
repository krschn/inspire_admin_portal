import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:inspire_admin_portal/core/errors/failures.dart';
import 'package:inspire_admin_portal/features/talks/domain/entities/speaker.dart';
import 'package:inspire_admin_portal/features/talks/domain/entities/talk.dart';
import 'package:inspire_admin_portal/features/talks/domain/repositories/talk_repository.dart';
import 'package:inspire_admin_portal/features/talks/domain/usecases/create_talk.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  late CreateTalk useCase;
  late MockTalkRepository mockRepository;

  setUp(() {
    mockRepository = MockTalkRepository();
    useCase = CreateTalk(mockRepository);
  });

  setUpAll(() {
    registerFallbackValue(
      Talk(
        date: DateTime.now(),
        title: '',
        description: '',
        speakers: const [],
        liveLink: '',
        duration: '',
        track: 1,
        venue: '',
      ),
    );
  });

  final testTalk = Talk(
    date: DateTime(2024, 1, 15),
    title: 'New Talk',
    description: 'New Description',
    speakers: const [
      Speaker(name: 'Speaker', image: 'https://example.com/img.jpg'),
    ],
    liveLink: 'https://example.com/live',
    duration: '30 min',
    track: 1,
    venue: 'Room 101',
  );

  final createdTalk = Talk(
    id: 'created-id',
    date: DateTime(2024, 1, 15),
    title: 'New Talk',
    description: 'New Description',
    speakers: const [
      Speaker(name: 'Speaker', image: 'https://example.com/img.jpg'),
    ],
    liveLink: 'https://example.com/live',
    duration: '30 min',
    track: 1,
    venue: 'Room 101',
  );

  group('CreateTalk', () {
    const eventId = 'event-123';

    test('should call repository.createTalk with correct parameters', () async {
      when(
        () => mockRepository.createTalk(eventId, testTalk),
      ).thenAnswer((_) async => Right(createdTalk));

      await useCase(eventId, testTalk);

      verify(() => mockRepository.createTalk(eventId, testTalk)).called(1);
    });

    test('should return created talk with id on success', () async {
      when(
        () => mockRepository.createTalk(eventId, testTalk),
      ).thenAnswer((_) async => Right(createdTalk));

      final result = await useCase(eventId, testTalk);

      expect(result.isRight(), isTrue);
      result.fold((failure) => fail('Expected Right but got Left'), (talk) {
        expect(talk.id, 'created-id');
        expect(talk.title, testTalk.title);
      });
    });

    test('should return ServerFailure on server error', () async {
      when(
        () => mockRepository.createTalk(eventId, testTalk),
      ).thenAnswer((_) async => const Left(ServerFailure('Failed to create')));

      final result = await useCase(eventId, testTalk);

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, 'Failed to create');
      }, (talk) => fail('Expected Left but got Right'));
    });

    test('should return NetworkFailure on network error', () async {
      when(
        () => mockRepository.createTalk(eventId, testTalk),
      ).thenAnswer((_) async => const Left(NetworkFailure()));

      final result = await useCase(eventId, testTalk);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (talk) => fail('Expected Left but got Right'),
      );
    });
  });
}

class MockTalkRepository extends Mock implements TalkRepository {}
