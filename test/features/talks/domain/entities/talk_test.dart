import 'package:flutter_test/flutter_test.dart';
import 'package:inspire_admin_portal/features/talks/domain/entities/talk.dart';
import 'package:inspire_admin_portal/features/talks/domain/entities/speaker.dart';

void main() {
  group('Talk', () {
    final testDate = DateTime(2024, 1, 15);
    final testSpeakers = [
      const Speaker(name: 'John Doe', image: 'https://example.com/john.jpg'),
      const Speaker(name: 'Jane Smith', image: 'https://example.com/jane.jpg'),
    ];

    Talk createTalk({
      String? id,
      DateTime? date,
      String? title,
      String? description,
      List<Speaker>? speakers,
      String? liveLink,
      String? duration,
      String? track,
      String? venue,
    }) {
      return Talk(
        id: id ?? 'test-id',
        date: date ?? testDate,
        title: title ?? 'Test Talk',
        description: description ?? 'Test Description',
        speakers: speakers ?? testSpeakers,
        liveLink: liveLink ?? 'https://example.com/live',
        duration: duration ?? '30 min',
        track: track ?? 'Track A',
        venue: venue ?? 'Room 101',
      );
    }

    test('should create Talk with all required fields', () {
      final talk = createTalk();

      expect(talk.id, 'test-id');
      expect(talk.date, testDate);
      expect(talk.title, 'Test Talk');
      expect(talk.description, 'Test Description');
      expect(talk.speakers, testSpeakers);
      expect(talk.liveLink, 'https://example.com/live');
      expect(talk.duration, '30 min');
      expect(talk.track, 'Track A');
      expect(talk.venue, 'Room 101');
    });

    test('should allow null id', () {
      final talk = Talk(
        date: testDate,
        title: 'Test Talk',
        description: 'Test Description',
        speakers: testSpeakers,
        liveLink: 'https://example.com/live',
        duration: '30 min',
        track: 'Track A',
        venue: 'Room 101',
      );

      expect(talk.id, isNull);
    });

    group('copyWith', () {
      test('should return a new Talk with updated id', () {
        final talk = createTalk();
        final updatedTalk = talk.copyWith(id: 'new-id');

        expect(updatedTalk.id, 'new-id');
        expect(updatedTalk.title, talk.title);
        expect(updatedTalk.date, talk.date);
      });

      test('should return a new Talk with updated title', () {
        final talk = createTalk();
        final updatedTalk = talk.copyWith(title: 'New Title');

        expect(updatedTalk.title, 'New Title');
        expect(updatedTalk.id, talk.id);
      });

      test('should return a new Talk with updated date', () {
        final talk = createTalk();
        final newDate = DateTime(2024, 2, 20);
        final updatedTalk = talk.copyWith(date: newDate);

        expect(updatedTalk.date, newDate);
        expect(updatedTalk.title, talk.title);
      });

      test('should return a new Talk with updated speakers', () {
        final talk = createTalk();
        final newSpeakers = [
          const Speaker(name: 'New Speaker', image: 'https://example.com/new.jpg'),
        ];
        final updatedTalk = talk.copyWith(speakers: newSpeakers);

        expect(updatedTalk.speakers, newSpeakers);
        expect(updatedTalk.title, talk.title);
      });

      test('should return a new Talk with all fields updated', () {
        final talk = createTalk();
        final newDate = DateTime(2024, 3, 25);
        final newSpeakers = [
          const Speaker(name: 'Speaker 3', image: 'https://example.com/s3.jpg'),
        ];

        final updatedTalk = talk.copyWith(
          id: 'updated-id',
          date: newDate,
          title: 'Updated Title',
          description: 'Updated Description',
          speakers: newSpeakers,
          liveLink: 'https://updated.com/live',
          duration: '45 min',
          track: 'Track B',
          venue: 'Room 202',
        );

        expect(updatedTalk.id, 'updated-id');
        expect(updatedTalk.date, newDate);
        expect(updatedTalk.title, 'Updated Title');
        expect(updatedTalk.description, 'Updated Description');
        expect(updatedTalk.speakers, newSpeakers);
        expect(updatedTalk.liveLink, 'https://updated.com/live');
        expect(updatedTalk.duration, '45 min');
        expect(updatedTalk.track, 'Track B');
        expect(updatedTalk.venue, 'Room 202');
      });

      test('should keep original values when not specified in copyWith', () {
        final talk = createTalk();
        final updatedTalk = talk.copyWith();

        expect(updatedTalk.id, talk.id);
        expect(updatedTalk.date, talk.date);
        expect(updatedTalk.title, talk.title);
        expect(updatedTalk.description, talk.description);
        expect(updatedTalk.speakers, talk.speakers);
        expect(updatedTalk.liveLink, talk.liveLink);
        expect(updatedTalk.duration, talk.duration);
        expect(updatedTalk.track, talk.track);
        expect(updatedTalk.venue, talk.venue);
      });
    });

    group('Equatable', () {
      test('should be equal when all properties are the same', () {
        final talk1 = createTalk();
        final talk2 = createTalk();

        expect(talk1, equals(talk2));
      });

      test('should not be equal when id is different', () {
        final talk1 = createTalk(id: 'id-1');
        final talk2 = createTalk(id: 'id-2');

        expect(talk1, isNot(equals(talk2)));
      });

      test('should not be equal when title is different', () {
        final talk1 = createTalk(title: 'Title 1');
        final talk2 = createTalk(title: 'Title 2');

        expect(talk1, isNot(equals(talk2)));
      });

      test('should not be equal when date is different', () {
        final talk1 = createTalk(date: DateTime(2024, 1, 1));
        final talk2 = createTalk(date: DateTime(2024, 1, 2));

        expect(talk1, isNot(equals(talk2)));
      });

      test('should have same hashCode when equal', () {
        final talk1 = createTalk();
        final talk2 = createTalk();

        expect(talk1.hashCode, equals(talk2.hashCode));
      });

      test('props should include all properties', () {
        final talk = createTalk();

        expect(talk.props, [
          talk.id,
          talk.date,
          talk.title,
          talk.description,
          talk.speakers,
          talk.liveLink,
          talk.duration,
          talk.track,
          talk.venue,
        ]);
      });
    });
  });
}
