import 'package:flutter_test/flutter_test.dart';
import 'package:inspire_admin_portal/features/talks/domain/entities/event.dart';

void main() {
  group('Event', () {
    test('should create Event with id and name', () {
      const event = Event(
        id: 'event-1',
        name: 'Tech Conference 2024',
      );

      expect(event.id, 'event-1');
      expect(event.name, 'Tech Conference 2024');
    });

    test('should create Event with id only (name is optional)', () {
      const event = Event(id: 'event-2');

      expect(event.id, 'event-2');
      expect(event.name, isNull);
    });

    group('Equatable', () {
      test('should be equal when all properties are the same', () {
        const event1 = Event(id: 'event-1', name: 'Conference');
        const event2 = Event(id: 'event-1', name: 'Conference');

        expect(event1, equals(event2));
      });

      test('should be equal when both have same id and null name', () {
        const event1 = Event(id: 'event-1');
        const event2 = Event(id: 'event-1');

        expect(event1, equals(event2));
      });

      test('should not be equal when id is different', () {
        const event1 = Event(id: 'event-1', name: 'Conference');
        const event2 = Event(id: 'event-2', name: 'Conference');

        expect(event1, isNot(equals(event2)));
      });

      test('should not be equal when name is different', () {
        const event1 = Event(id: 'event-1', name: 'Conference 1');
        const event2 = Event(id: 'event-1', name: 'Conference 2');

        expect(event1, isNot(equals(event2)));
      });

      test('should not be equal when one has name and other does not', () {
        const event1 = Event(id: 'event-1', name: 'Conference');
        const event2 = Event(id: 'event-1');

        expect(event1, isNot(equals(event2)));
      });

      test('should have same hashCode when equal', () {
        const event1 = Event(id: 'event-1', name: 'Conference');
        const event2 = Event(id: 'event-1', name: 'Conference');

        expect(event1.hashCode, equals(event2.hashCode));
      });

      test('props should include id and name', () {
        const event = Event(id: 'event-1', name: 'Conference');

        expect(event.props, ['event-1', 'Conference']);
      });

      test('props should include null name when not provided', () {
        const event = Event(id: 'event-1');

        expect(event.props, ['event-1', null]);
      });
    });
  });
}
