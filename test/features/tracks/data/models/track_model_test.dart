import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspire_admin_portal/features/tracks/data/models/track_model.dart';
import 'package:inspire_admin_portal/features/tracks/domain/entities/track.dart';

void main() {
  group('TrackModel', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    Map<String, dynamic> createFirestoreData({
      int? trackNumber,
      String? trackDescription,
      String? trackColor,
    }) {
      return {
        'track_number': trackNumber ?? 1,
        'track_description': trackDescription ?? 'Test Track',
        'track_color': trackColor ?? '#2E6CA4',
      };
    }

    group('fromFirestore', () {
      test('should create TrackModel from complete Firestore document', () async {
        await fakeFirestore
            .collection('tracks')
            .doc('track-1')
            .set(createFirestoreData());

        final doc = await fakeFirestore.collection('tracks').doc('track-1').get();
        final model = TrackModel.fromFirestore(doc);

        expect(model.id, 'track-1');
        expect(model.trackNumber, 1);
        expect(model.trackDescription, 'Test Track');
        expect(model.trackColor, '#2E6CA4');
      });

      test('should use 0 when track_number is null', () async {
        final data = createFirestoreData();
        data['track_number'] = null;
        await fakeFirestore.collection('tracks').doc('track-2').set(data);

        final doc = await fakeFirestore.collection('tracks').doc('track-2').get();
        final model = TrackModel.fromFirestore(doc);

        expect(model.trackNumber, 0);
      });

      test('should use empty string when track_description is null', () async {
        final data = createFirestoreData();
        data['track_description'] = null;
        await fakeFirestore.collection('tracks').doc('track-3').set(data);

        final doc = await fakeFirestore.collection('tracks').doc('track-3').get();
        final model = TrackModel.fromFirestore(doc);

        expect(model.trackDescription, '');
      });

      test('should use default color when track_color is null', () async {
        final data = createFirestoreData();
        data['track_color'] = null;
        await fakeFirestore.collection('tracks').doc('track-4').set(data);

        final doc = await fakeFirestore.collection('tracks').doc('track-4').get();
        final model = TrackModel.fromFirestore(doc);

        expect(model.trackColor, '#2E6CA4');
      });

      test('should correctly parse different track numbers', () async {
        await fakeFirestore
            .collection('tracks')
            .doc('track-5')
            .set(createFirestoreData(trackNumber: 7));

        final doc = await fakeFirestore.collection('tracks').doc('track-5').get();
        final model = TrackModel.fromFirestore(doc);

        expect(model.trackNumber, 7);
      });
    });

    group('fromEntity', () {
      test('should create TrackModel from Track entity', () {
        const track = Track(
          id: 'entity-id',
          trackNumber: 3,
          trackDescription: 'Entity Track',
          trackColor: '#FF5733',
        );

        final model = TrackModel.fromEntity(track);

        expect(model.id, 'entity-id');
        expect(model.trackNumber, 3);
        expect(model.trackDescription, 'Entity Track');
        expect(model.trackColor, '#FF5733');
      });

      test('should handle null id from entity', () {
        const track = Track(
          trackNumber: 1,
          trackDescription: 'No ID Track',
          trackColor: '#2E6CA4',
        );

        final model = TrackModel.fromEntity(track);

        expect(model.id, isNull);
      });
    });

    group('toFirestore', () {
      test('should convert TrackModel to Firestore map', () {
        const model = TrackModel(
          id: 'model-id',
          trackNumber: 5,
          trackDescription: 'Model Track',
          trackColor: '#123456',
        );

        final firestoreMap = model.toFirestore();

        expect(firestoreMap['track_number'], 5);
        expect(firestoreMap['track_description'], 'Model Track');
        expect(firestoreMap['track_color'], '#123456');
      });

      test('should not include id in Firestore map', () {
        const model = TrackModel(
          id: 'model-id',
          trackNumber: 1,
          trackDescription: 'Test',
          trackColor: '#2E6CA4',
        );

        final firestoreMap = model.toFirestore();

        expect(firestoreMap.containsKey('id'), isFalse);
      });

      test('should use snake_case keys', () {
        const model = TrackModel(
          trackNumber: 1,
          trackDescription: 'Test',
          trackColor: '#2E6CA4',
        );

        final firestoreMap = model.toFirestore();

        expect(firestoreMap.containsKey('track_number'), isTrue);
        expect(firestoreMap.containsKey('track_description'), isTrue);
        expect(firestoreMap.containsKey('track_color'), isTrue);
        expect(firestoreMap.containsKey('trackNumber'), isFalse);
        expect(firestoreMap.containsKey('trackDescription'), isFalse);
        expect(firestoreMap.containsKey('trackColor'), isFalse);
      });
    });

    group('toEntity', () {
      test('should convert TrackModel to Track entity', () {
        const model = TrackModel(
          id: 'model-id',
          trackNumber: 4,
          trackDescription: 'Model Track',
          trackColor: '#ABCDEF',
        );

        final entity = model.toEntity();

        expect(entity, isA<Track>());
        expect(entity.id, 'model-id');
        expect(entity.trackNumber, 4);
        expect(entity.trackDescription, 'Model Track');
        expect(entity.trackColor, '#ABCDEF');
      });
    });

    group('round-trip conversion', () {
      test(
        'should preserve data through entity -> model -> firestore -> model -> entity',
        () async {
          const originalEntity = Track(
            id: 'round-trip-id',
            trackNumber: 7,
            trackDescription: 'Round Trip Track',
            trackColor: '#FEDCBA',
          );

          // Entity -> Model
          final model1 = TrackModel.fromEntity(originalEntity);

          // Model -> Firestore
          await fakeFirestore
              .collection('tracks')
              .doc('round-trip-id')
              .set(model1.toFirestore());

          // Firestore -> Model
          final doc = await fakeFirestore
              .collection('tracks')
              .doc('round-trip-id')
              .get();
          final model2 = TrackModel.fromFirestore(doc);

          // Model -> Entity
          final finalEntity = model2.toEntity();

          expect(finalEntity.id, originalEntity.id);
          expect(finalEntity.trackNumber, originalEntity.trackNumber);
          expect(finalEntity.trackDescription, originalEntity.trackDescription);
          expect(finalEntity.trackColor, originalEntity.trackColor);
        },
      );
    });
  });
}
