import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:inspire_admin_portal/core/errors/failures.dart';
import 'package:inspire_admin_portal/features/talks/domain/entities/event.dart';
import 'package:inspire_admin_portal/features/talks/domain/repositories/talk_repository.dart';
import 'package:inspire_admin_portal/features/talks/domain/usecases/get_events.dart';

class MockTalkRepository extends Mock implements TalkRepository {}

void main() {
  late GetEvents useCase;
  late MockTalkRepository mockRepository;

  setUp(() {
    mockRepository = MockTalkRepository();
    useCase = GetEvents(mockRepository);
  });

  final testEvents = [
    const Event(id: 'event-1', name: 'Tech Conference 2024'),
    const Event(id: 'event-2', name: 'Developer Summit'),
    const Event(id: 'event-3'),
  ];

  group('GetEvents', () {
    test('should call repository.getEvents', () async {
      when(() => mockRepository.getEvents())
          .thenAnswer((_) async => Right(testEvents));

      await useCase();

      verify(() => mockRepository.getEvents()).called(1);
    });

    test('should return list of events on success', () async {
      when(() => mockRepository.getEvents())
          .thenAnswer((_) async => Right(testEvents));

      final result = await useCase();

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected Right but got Left'),
        (events) {
          expect(events, equals(testEvents));
          expect(events.length, 3);
          expect(events[0].name, 'Tech Conference 2024');
          expect(events[2].name, isNull);
        },
      );
    });

    test('should return empty list when no events exist', () async {
      when(() => mockRepository.getEvents())
          .thenAnswer((_) async => const Right([]));

      final result = await useCase();

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected Right but got Left'),
        (events) => expect(events, isEmpty),
      );
    });

    test('should return ServerFailure on server error', () async {
      when(() => mockRepository.getEvents())
          .thenAnswer((_) async => const Left(ServerFailure('Server error')));

      final result = await useCase();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, 'Server error');
        },
        (events) => fail('Expected Left but got Right'),
      );
    });

    test('should return NetworkFailure on network error', () async {
      when(() => mockRepository.getEvents())
          .thenAnswer((_) async => const Left(NetworkFailure()));

      final result = await useCase();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (events) => fail('Expected Left but got Right'),
      );
    });
  });
}
