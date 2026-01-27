import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspire_admin_portal/features/talks/data/models/talk_model.dart';
import 'package:inspire_admin_portal/features/talks/domain/entities/talk.dart';
import 'package:inspire_admin_portal/features/talks/domain/entities/speaker.dart';

void main() {
  group('TalkModel', () {
    late FakeFirebaseFirestore fakeFirestore;
    final testDate = DateTime(2024, 1, 15, 10, 30);
    final testTimestamp = Timestamp.fromDate(testDate);

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    Map<String, dynamic> createFirestoreData({
      Timestamp? date,
      String? title,
      String? description,
      List<Map<String, dynamic>>? speakers,
      String? liveLink,
      String? duration,
      String? track,
      String? venue,
    }) {
      return {
        'date': date ?? testTimestamp,
        'title': title ?? 'Test Talk',
        'description': description ?? 'Test Description',
        'speakers': speakers ?? [
          {'name': 'John Doe', 'image': 'https://example.com/john.jpg'},
        ],
        'live_link': liveLink ?? 'https://example.com/live',
        'duration': duration ?? '30 min',
        'track': track ?? 'Track A',
        'venue': venue ?? 'Room 101',
      };
    }

    group('fromFirestore', () {
      test('should create TalkModel from complete Firestore document', () async {
        await fakeFirestore.collection('talks').doc('talk-1').set(createFirestoreData());

        final doc = await fakeFirestore.collection('talks').doc('talk-1').get();
        final model = TalkModel.fromFirestore(doc);

        expect(model.id, 'talk-1');
        expect(model.date.year, 2024);
        expect(model.date.month, 1);
        expect(model.date.day, 15);
        expect(model.title, 'Test Talk');
        expect(model.description, 'Test Description');
        expect(model.speakers.length, 1);
        expect(model.speakers.first.name, 'John Doe');
        expect(model.liveLink, 'https://example.com/live');
        expect(model.duration, '30 min');
        expect(model.track, 'Track A');
        expect(model.venue, 'Room 101');
      });

      test('should use DateTime.now() when date is null', () async {
        final data = createFirestoreData();
        data['date'] = null;
        await fakeFirestore.collection('talks').doc('talk-2').set(data);

        final doc = await fakeFirestore.collection('talks').doc('talk-2').get();
        final beforeParse = DateTime.now();
        final model = TalkModel.fromFirestore(doc);
        final afterParse = DateTime.now();

        expect(model.date.isAfter(beforeParse.subtract(const Duration(seconds: 1))), isTrue);
        expect(model.date.isBefore(afterParse.add(const Duration(seconds: 1))), isTrue);
      });

      test('should use empty string when title is null', () async {
        final data = createFirestoreData();
        data['title'] = null;
        await fakeFirestore.collection('talks').doc('talk-3').set(data);

        final doc = await fakeFirestore.collection('talks').doc('talk-3').get();
        final model = TalkModel.fromFirestore(doc);

        expect(model.title, '');
      });

      test('should use empty string when description is null', () async {
        final data = createFirestoreData();
        data['description'] = null;
        await fakeFirestore.collection('talks').doc('talk-4').set(data);

        final doc = await fakeFirestore.collection('talks').doc('talk-4').get();
        final model = TalkModel.fromFirestore(doc);

        expect(model.description, '');
      });

      test('should parse multiple speakers', () async {
        final data = createFirestoreData(
          speakers: [
            {'name': 'Speaker 1', 'image': 'https://example.com/1.jpg'},
            {'name': 'Speaker 2', 'image': 'https://example.com/2.jpg'},
            {'name': 'Speaker 3', 'image': 'https://example.com/3.jpg'},
          ],
        );
        await fakeFirestore.collection('talks').doc('talk-5').set(data);

        final doc = await fakeFirestore.collection('talks').doc('talk-5').get();
        final model = TalkModel.fromFirestore(doc);

        expect(model.speakers.length, 3);
        expect(model.speakers[0].name, 'Speaker 1');
        expect(model.speakers[1].name, 'Speaker 2');
        expect(model.speakers[2].name, 'Speaker 3');
      });

      test('should return empty list when speakers is null', () async {
        final data = createFirestoreData();
        data['speakers'] = null;
        await fakeFirestore.collection('talks').doc('talk-6').set(data);

        final doc = await fakeFirestore.collection('talks').doc('talk-6').get();
        final model = TalkModel.fromFirestore(doc);

        expect(model.speakers, isEmpty);
      });

      test('should return empty list when speakers is not a list', () async {
        final data = createFirestoreData();
        data['speakers'] = 'not a list';
        await fakeFirestore.collection('talks').doc('talk-7').set(data);

        final doc = await fakeFirestore.collection('talks').doc('talk-7').get();
        final model = TalkModel.fromFirestore(doc);

        expect(model.speakers, isEmpty);
      });

      test('should filter out non-map items from speakers list', () async {
        final data = createFirestoreData();
        data['speakers'] = [
          {'name': 'Valid Speaker', 'image': 'https://example.com/valid.jpg'},
          'invalid string item',
          123,
          null,
        ];
        await fakeFirestore.collection('talks').doc('talk-8').set(data);

        final doc = await fakeFirestore.collection('talks').doc('talk-8').get();
        final model = TalkModel.fromFirestore(doc);

        expect(model.speakers.length, 1);
        expect(model.speakers.first.name, 'Valid Speaker');
      });
    });

    group('fromEntity', () {
      test('should create TalkModel from Talk entity', () {
        final talk = Talk(
          id: 'entity-id',
          date: testDate,
          title: 'Entity Talk',
          description: 'Entity Description',
          speakers: const [
            Speaker(name: 'Entity Speaker', image: 'https://example.com/entity.jpg'),
          ],
          liveLink: 'https://entity.com/live',
          duration: '45 min',
          track: 'Track B',
          venue: 'Room 202',
        );

        final model = TalkModel.fromEntity(talk);

        expect(model.id, 'entity-id');
        expect(model.date, testDate);
        expect(model.title, 'Entity Talk');
        expect(model.description, 'Entity Description');
        expect(model.speakers.length, 1);
        expect(model.speakers.first.name, 'Entity Speaker');
        expect(model.liveLink, 'https://entity.com/live');
        expect(model.duration, '45 min');
        expect(model.track, 'Track B');
        expect(model.venue, 'Room 202');
      });

      test('should handle null id from entity', () {
        final talk = Talk(
          date: testDate,
          title: 'No ID Talk',
          description: 'Description',
          speakers: const [],
          liveLink: '',
          duration: '',
          track: '',
          venue: '',
        );

        final model = TalkModel.fromEntity(talk);

        expect(model.id, isNull);
      });
    });

    group('toFirestore', () {
      test('should convert TalkModel to Firestore map', () {
        final model = TalkModel(
          id: 'model-id',
          date: testDate,
          title: 'Model Talk',
          description: 'Model Description',
          speakers: const [
            Speaker(name: 'Model Speaker', image: 'https://example.com/model.jpg'),
          ],
          liveLink: 'https://model.com/live',
          duration: '60 min',
          track: 'Track C',
          venue: 'Room 303',
        );

        final firestoreMap = model.toFirestore();

        expect(firestoreMap['date'], isA<Timestamp>());
        expect((firestoreMap['date'] as Timestamp).toDate().year, testDate.year);
        expect(firestoreMap['title'], 'Model Talk');
        expect(firestoreMap['description'], 'Model Description');
        expect(firestoreMap['speakers'], isA<List>());
        expect((firestoreMap['speakers'] as List).length, 1);
        expect((firestoreMap['speakers'] as List).first['name'], 'Model Speaker');
        expect(firestoreMap['live_link'], 'https://model.com/live');
        expect(firestoreMap['duration'], '60 min');
        expect(firestoreMap['track'], 'Track C');
        expect(firestoreMap['venue'], 'Room 303');
      });

      test('should not include id in Firestore map', () {
        final model = TalkModel(
          id: 'model-id',
          date: testDate,
          title: 'Test',
          description: '',
          speakers: const [],
          liveLink: '',
          duration: '',
          track: '',
          venue: '',
        );

        final firestoreMap = model.toFirestore();

        expect(firestoreMap.containsKey('id'), isFalse);
      });
    });

    group('toEntity', () {
      test('should convert TalkModel to Talk entity', () {
        final model = TalkModel(
          id: 'model-id',
          date: testDate,
          title: 'Model Talk',
          description: 'Model Description',
          speakers: const [
            Speaker(name: 'Model Speaker', image: 'https://example.com/model.jpg'),
          ],
          liveLink: 'https://model.com/live',
          duration: '60 min',
          track: 'Track C',
          venue: 'Room 303',
        );

        final entity = model.toEntity();

        expect(entity, isA<Talk>());
        expect(entity.id, 'model-id');
        expect(entity.date, testDate);
        expect(entity.title, 'Model Talk');
        expect(entity.description, 'Model Description');
        expect(entity.speakers.length, 1);
        expect(entity.liveLink, 'https://model.com/live');
        expect(entity.duration, '60 min');
        expect(entity.track, 'Track C');
        expect(entity.venue, 'Room 303');
      });
    });

    group('round-trip conversion', () {
      test('should preserve data through entity -> model -> firestore -> model -> entity', () async {
        final originalEntity = Talk(
          id: 'round-trip-id',
          date: testDate,
          title: 'Round Trip Talk',
          description: 'Round Trip Description',
          speakers: const [
            Speaker(name: 'RT Speaker', image: 'https://example.com/rt.jpg'),
          ],
          liveLink: 'https://roundtrip.com/live',
          duration: '90 min',
          track: 'Track RT',
          venue: 'Room RT',
        );

        // Entity -> Model
        final model1 = TalkModel.fromEntity(originalEntity);

        // Model -> Firestore
        await fakeFirestore
            .collection('talks')
            .doc('round-trip-id')
            .set(model1.toFirestore());

        // Firestore -> Model
        final doc = await fakeFirestore.collection('talks').doc('round-trip-id').get();
        final model2 = TalkModel.fromFirestore(doc);

        // Model -> Entity
        final finalEntity = model2.toEntity();

        expect(finalEntity.id, originalEntity.id);
        expect(finalEntity.date.year, originalEntity.date.year);
        expect(finalEntity.date.month, originalEntity.date.month);
        expect(finalEntity.date.day, originalEntity.date.day);
        expect(finalEntity.title, originalEntity.title);
        expect(finalEntity.description, originalEntity.description);
        expect(finalEntity.speakers.length, originalEntity.speakers.length);
        expect(finalEntity.speakers.first.name, originalEntity.speakers.first.name);
        expect(finalEntity.liveLink, originalEntity.liveLink);
        expect(finalEntity.duration, originalEntity.duration);
        expect(finalEntity.track, originalEntity.track);
        expect(finalEntity.venue, originalEntity.venue);
      });
    });
  });
}
