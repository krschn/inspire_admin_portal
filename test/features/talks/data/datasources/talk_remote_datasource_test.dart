import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspire_admin_portal/core/errors/exceptions.dart';
import 'package:inspire_admin_portal/features/talks/data/datasources/talk_remote_datasource.dart';
import 'package:inspire_admin_portal/features/talks/data/models/talk_model.dart';
import 'package:inspire_admin_portal/features/talks/domain/entities/speaker.dart';

void main() {
  late TalkRemoteDataSourceImpl dataSource;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    dataSource = TalkRemoteDataSourceImpl(fakeFirestore);
  });

  final testDate = DateTime(2024, 1, 15);
  final testTimestamp = Timestamp.fromDate(testDate);

  Map<String, dynamic> createTalkData({
    String? title,
    Timestamp? date,
    String? description,
    List<Map<String, dynamic>>? speakers,
  }) {
    return {
      'title': title ?? 'Test Talk',
      'date': date ?? testTimestamp,
      'description': description ?? 'Test Description',
      'speakers': speakers ?? [
        {'name': 'Speaker 1', 'image': 'https://example.com/1.jpg'},
      ],
      'live_link': 'https://example.com/live',
      'duration': '30 min',
      'track': 'Track A',
      'venue': 'Room 101',
    };
  }

  group('TalkRemoteDataSourceImpl', () {
    group('getEvents', () {
      test('should return list of EventModels from Firestore', () async {
        await fakeFirestore.collection('events').doc('event-1').set({
          'name': 'Tech Conference 2024',
        });
        await fakeFirestore.collection('events').doc('event-2').set({
          'name': 'Developer Summit',
        });

        final events = await dataSource.getEvents();

        expect(events.length, 2);
        expect(events.any((e) => e.id == 'event-1'), isTrue);
        expect(events.any((e) => e.id == 'event-2'), isTrue);
      });

      test('should return empty list when no events exist', () async {
        final events = await dataSource.getEvents();

        expect(events, isEmpty);
      });
    });

    group('getTalks', () {
      const eventId = 'event-123';

      test('should return list of TalkModels from Firestore', () async {
        await fakeFirestore
            .collection('events')
            .doc(eventId)
            .collection('talk')
            .doc('talk-1')
            .set(createTalkData(title: 'Talk 1'));
        await fakeFirestore
            .collection('events')
            .doc(eventId)
            .collection('talk')
            .doc('talk-2')
            .set(createTalkData(title: 'Talk 2'));

        final talks = await dataSource.getTalks(eventId);

        expect(talks.length, 2);
        expect(talks.any((t) => t.title == 'Talk 1'), isTrue);
        expect(talks.any((t) => t.title == 'Talk 2'), isTrue);
      });

      test('should return empty list when no talks exist', () async {
        final talks = await dataSource.getTalks(eventId);

        expect(talks, isEmpty);
      });

      test('should order talks by date ascending', () async {
        final date1 = DateTime(2024, 1, 15);
        final date2 = DateTime(2024, 1, 10);
        final date3 = DateTime(2024, 1, 20);

        await fakeFirestore
            .collection('events')
            .doc(eventId)
            .collection('talk')
            .doc('talk-1')
            .set(createTalkData(title: 'Talk 1', date: Timestamp.fromDate(date1)));
        await fakeFirestore
            .collection('events')
            .doc(eventId)
            .collection('talk')
            .doc('talk-2')
            .set(createTalkData(title: 'Talk 2', date: Timestamp.fromDate(date2)));
        await fakeFirestore
            .collection('events')
            .doc(eventId)
            .collection('talk')
            .doc('talk-3')
            .set(createTalkData(title: 'Talk 3', date: Timestamp.fromDate(date3)));

        final talks = await dataSource.getTalks(eventId);

        expect(talks.length, 3);
        expect(talks[0].title, 'Talk 2'); // Jan 10
        expect(talks[1].title, 'Talk 1'); // Jan 15
        expect(talks[2].title, 'Talk 3'); // Jan 20
      });
    });

    group('createTalk', () {
      const eventId = 'event-123';

      test('should create talk and return TalkModel with id', () async {
        final talkModel = TalkModel(
          date: testDate,
          title: 'New Talk',
          description: 'New Description',
          speakers: const [Speaker(name: 'Speaker', image: '')],
          liveLink: 'https://example.com',
          duration: '30 min',
          track: 'Track A',
          venue: 'Room 101',
        );

        final result = await dataSource.createTalk(eventId, talkModel);

        expect(result.id, isNotNull);
        expect(result.title, 'New Talk');
        expect(result.description, 'New Description');

        // Verify it was actually stored
        final snapshot = await fakeFirestore
            .collection('events')
            .doc(eventId)
            .collection('talk')
            .get();
        expect(snapshot.docs.length, 1);
      });
    });

    group('updateTalk', () {
      const eventId = 'event-123';
      const talkId = 'talk-456';

      test('should update talk and return updated TalkModel', () async {
        // First create a talk
        await fakeFirestore
            .collection('events')
            .doc(eventId)
            .collection('talk')
            .doc(talkId)
            .set(createTalkData(title: 'Original Title'));

        final updatedTalkModel = TalkModel(
          id: talkId,
          date: testDate,
          title: 'Updated Title',
          description: 'Updated Description',
          speakers: const [],
          liveLink: '',
          duration: '45 min',
          track: 'Track B',
          venue: 'Room 202',
        );

        final result = await dataSource.updateTalk(eventId, updatedTalkModel);

        expect(result.id, talkId);
        expect(result.title, 'Updated Title');
        expect(result.description, 'Updated Description');
      });

      test('should throw ServerException when talk id is null', () async {
        final talkModelWithoutId = TalkModel(
          date: testDate,
          title: 'No ID Talk',
          description: '',
          speakers: const [],
          liveLink: '',
          duration: '',
          track: '',
          venue: '',
        );

        expect(
          () => dataSource.updateTalk(eventId, talkModelWithoutId),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('deleteTalk', () {
      const eventId = 'event-123';
      const talkId = 'talk-456';

      test('should delete talk from Firestore', () async {
        // First create a talk
        await fakeFirestore
            .collection('events')
            .doc(eventId)
            .collection('talk')
            .doc(talkId)
            .set(createTalkData());

        await dataSource.deleteTalk(eventId, talkId);

        final doc = await fakeFirestore
            .collection('events')
            .doc(eventId)
            .collection('talk')
            .doc(talkId)
            .get();
        expect(doc.exists, isFalse);
      });
    });

    group('findTalkByTitleAndDate', () {
      const eventId = 'event-123';

      test('should return TalkModel when talk exists with matching title and date', () async {
        final targetDate = DateTime(2024, 1, 15, 10, 30);
        await fakeFirestore
            .collection('events')
            .doc(eventId)
            .collection('talk')
            .doc('matching-talk')
            .set(createTalkData(
              title: 'Target Talk',
              date: Timestamp.fromDate(targetDate),
            ));

        final result = await dataSource.findTalkByTitleAndDate(
          eventId,
          'Target Talk',
          targetDate,
        );

        expect(result, isNotNull);
        expect(result!.title, 'Target Talk');
        expect(result.id, 'matching-talk');
      });

      test('should return null when no talk matches', () async {
        await fakeFirestore
            .collection('events')
            .doc(eventId)
            .collection('talk')
            .doc('other-talk')
            .set(createTalkData(
              title: 'Other Talk',
              date: Timestamp.fromDate(DateTime(2024, 1, 15)),
            ));

        final result = await dataSource.findTalkByTitleAndDate(
          eventId,
          'Non-existent Talk',
          DateTime(2024, 1, 15),
        );

        expect(result, isNull);
      });

      test('should return null when title matches but date does not', () async {
        await fakeFirestore
            .collection('events')
            .doc(eventId)
            .collection('talk')
            .doc('different-date-talk')
            .set(createTalkData(
              title: 'Same Title',
              date: Timestamp.fromDate(DateTime(2024, 1, 15)),
            ));

        final result = await dataSource.findTalkByTitleAndDate(
          eventId,
          'Same Title',
          DateTime(2024, 1, 20), // Different date
        );

        expect(result, isNull);
      });

      test('should match talk within the same day regardless of time', () async {
        final storedDate = DateTime(2024, 1, 15, 10, 30);
        final searchDate = DateTime(2024, 1, 15, 14, 0);

        await fakeFirestore
            .collection('events')
            .doc(eventId)
            .collection('talk')
            .doc('same-day-talk')
            .set(createTalkData(
              title: 'Same Day Talk',
              date: Timestamp.fromDate(storedDate),
            ));

        final result = await dataSource.findTalkByTitleAndDate(
          eventId,
          'Same Day Talk',
          searchDate,
        );

        expect(result, isNotNull);
        expect(result!.title, 'Same Day Talk');
      });
    });
  });
}
