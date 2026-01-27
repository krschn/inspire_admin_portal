import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:inspire_admin_portal/core/errors/failures.dart';
import 'package:inspire_admin_portal/features/talks/domain/entities/talk.dart';
import 'package:inspire_admin_portal/features/talks/domain/entities/speaker.dart';
import 'package:inspire_admin_portal/features/talks/domain/repositories/talk_repository.dart';
import 'package:inspire_admin_portal/features/talks/domain/usecases/get_talks.dart';

class MockTalkRepository extends Mock implements TalkRepository {}

void main() {
  late GetTalks useCase;
  late MockTalkRepository mockRepository;

  setUp(() {
    mockRepository = MockTalkRepository();
    useCase = GetTalks(mockRepository);
  });

  final testTalks = [
    Talk(
      id: 'talk-1',
      date: DateTime(2024, 1, 15),
      title: 'Talk 1',
      description: 'Description 1',
      speakers: const [Speaker(name: 'Speaker 1', image: '')],
      liveLink: '',
      duration: '30 min',
      track: 'Track A',
      venue: 'Room 101',
    ),
    Talk(
      id: 'talk-2',
      date: DateTime(2024, 1, 16),
      title: 'Talk 2',
      description: 'Description 2',
      speakers: const [],
      liveLink: '',
      duration: '45 min',
      track: 'Track B',
      venue: 'Room 102',
    ),
  ];

  group('GetTalks', () {
    const eventId = 'event-123';

    test('should call repository.getTalks with correct eventId', () async {
      when(() => mockRepository.getTalks(eventId))
          .thenAnswer((_) async => Right(testTalks));

      await useCase(eventId);

      verify(() => mockRepository.getTalks(eventId)).called(1);
    });

    test('should return list of talks on success', () async {
      when(() => mockRepository.getTalks(eventId))
          .thenAnswer((_) async => Right(testTalks));

      final result = await useCase(eventId);

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected Right but got Left'),
        (talks) {
          expect(talks, equals(testTalks));
          expect(talks.length, 2);
        },
      );
    });

    test('should return empty list when no talks exist', () async {
      when(() => mockRepository.getTalks(eventId))
          .thenAnswer((_) async => const Right([]));

      final result = await useCase(eventId);

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected Right but got Left'),
        (talks) => expect(talks, isEmpty),
      );
    });

    test('should return ServerFailure on server error', () async {
      when(() => mockRepository.getTalks(eventId))
          .thenAnswer((_) async => const Left(ServerFailure('Server error')));

      final result = await useCase(eventId);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'Server error');
        },
        (talks) => fail('Expected Left but got Right'),
      );
    });

    test('should return NetworkFailure on network error', () async {
      when(() => mockRepository.getTalks(eventId))
          .thenAnswer((_) async => const Left(NetworkFailure()));

      final result = await useCase(eventId);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (talks) => fail('Expected Left but got Right'),
      );
    });
  });
}
