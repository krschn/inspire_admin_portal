import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspire_admin_portal/features/talks/data/models/event_model.dart';
import 'package:inspire_admin_portal/features/talks/domain/entities/event.dart';

void main() {
  group('EventModel', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    group('fromFirestore', () {
      test('should create EventModel from Firestore document with name', () async {
        await fakeFirestore.collection('events').doc('event-1').set({
          'name': 'Tech Conference 2024',
        });

        final doc = await fakeFirestore.collection('events').doc('event-1').get();
        final model = EventModel.fromFirestore(doc);

        expect(model.id, 'event-1');
        expect(model.name, 'Tech Conference 2024');
      });

      test('should create EventModel from Firestore document without name', () async {
        await fakeFirestore.collection('events').doc('event-2').set({});

        final doc = await fakeFirestore.collection('events').doc('event-2').get();
        final model = EventModel.fromFirestore(doc);

        expect(model.id, 'event-2');
        expect(model.name, isNull);
      });

      test('should handle null name field', () async {
        await fakeFirestore.collection('events').doc('event-3').set({
          'name': null,
        });

        final doc = await fakeFirestore.collection('events').doc('event-3').get();
        final model = EventModel.fromFirestore(doc);

        expect(model.id, 'event-3');
        expect(model.name, isNull);
      });

      test('should use document id as model id', () async {
        await fakeFirestore.collection('events').doc('custom-doc-id').set({
          'name': 'Event Name',
        });

        final doc = await fakeFirestore.collection('events').doc('custom-doc-id').get();
        final model = EventModel.fromFirestore(doc);

        expect(model.id, 'custom-doc-id');
      });
    });

    group('toEntity', () {
      test('should convert EventModel to Event entity with name', () {
        const model = EventModel(
          id: 'event-1',
          name: 'Tech Conference 2024',
        );

        final entity = model.toEntity();

        expect(entity, isA<Event>());
        expect(entity.id, 'event-1');
        expect(entity.name, 'Tech Conference 2024');
      });

      test('should convert EventModel to Event entity without name', () {
        const model = EventModel(id: 'event-2');

        final entity = model.toEntity();

        expect(entity, isA<Event>());
        expect(entity.id, 'event-2');
        expect(entity.name, isNull);
      });
    });

    group('inheritance', () {
      test('EventModel should extend Event', () {
        const model = EventModel(id: 'event-1', name: 'Test');

        expect(model, isA<Event>());
      });

      test('EventModel should be equatable through Event inheritance', () {
        const model1 = EventModel(id: 'event-1', name: 'Test');
        const model2 = EventModel(id: 'event-1', name: 'Test');

        expect(model1, equals(model2));
      });
    });

    group('round-trip conversion', () {
      test('should preserve data through Firestore -> model -> entity', () async {
        await fakeFirestore.collection('events').doc('test-event').set({
          'name': 'Round Trip Event',
        });

        final doc = await fakeFirestore.collection('events').doc('test-event').get();
        final model = EventModel.fromFirestore(doc);
        final entity = model.toEntity();

        expect(entity.id, 'test-event');
        expect(entity.name, 'Round Trip Event');
      });
    });
  });
}
