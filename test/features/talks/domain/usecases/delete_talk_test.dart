import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:inspire_admin_portal/core/errors/failures.dart';
import 'package:inspire_admin_portal/features/talks/domain/repositories/talk_repository.dart';
import 'package:inspire_admin_portal/features/talks/domain/usecases/delete_talk.dart';

class MockTalkRepository extends Mock implements TalkRepository {}

void main() {
  late DeleteTalk useCase;
  late MockTalkRepository mockRepository;

  setUp(() {
    mockRepository = MockTalkRepository();
    useCase = DeleteTalk(mockRepository);
  });

  group('DeleteTalk', () {
    const eventId = 'event-123';
    const talkId = 'talk-456';

    test('should call repository.deleteTalk with correct parameters', () async {
      when(() => mockRepository.deleteTalk(eventId, talkId))
          .thenAnswer((_) async => const Right(null));

      await useCase(eventId, talkId);

      verify(() => mockRepository.deleteTalk(eventId, talkId)).called(1);
    });

    test('should return Right(null) on success', () async {
      when(() => mockRepository.deleteTalk(eventId, talkId))
          .thenAnswer((_) async => const Right(null));

      final result = await useCase(eventId, talkId);

      expect(result.isRight(), isTrue);
    });

    test('should return ServerFailure on server error', () async {
      when(() => mockRepository.deleteTalk(eventId, talkId))
          .thenAnswer((_) async => const Left(ServerFailure('Failed to delete')));

      final result = await useCase(eventId, talkId);

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
      when(() => mockRepository.deleteTalk(eventId, talkId))
          .thenAnswer((_) async => const Left(NetworkFailure()));

      final result = await useCase(eventId, talkId);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Expected Left but got Right'),
      );
    });
  });
}
