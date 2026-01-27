import 'package:flutter_test/flutter_test.dart';
import 'package:inspire_admin_portal/features/talks/domain/entities/speaker.dart';

void main() {
  group('Speaker', () {
    test('should create Speaker with all required fields', () {
      const speaker = Speaker(
        name: 'John Doe',
        image: 'https://example.com/john.jpg',
      );

      expect(speaker.name, 'John Doe');
      expect(speaker.image, 'https://example.com/john.jpg');
    });

    group('copyWith', () {
      test('should return a new Speaker with updated name', () {
        const speaker = Speaker(
          name: 'John Doe',
          image: 'https://example.com/john.jpg',
        );
        final updatedSpeaker = speaker.copyWith(name: 'Jane Smith');

        expect(updatedSpeaker.name, 'Jane Smith');
        expect(updatedSpeaker.image, speaker.image);
      });

      test('should return a new Speaker with updated image', () {
        const speaker = Speaker(
          name: 'John Doe',
          image: 'https://example.com/john.jpg',
        );
        final updatedSpeaker = speaker.copyWith(image: 'https://example.com/new.jpg');

        expect(updatedSpeaker.name, speaker.name);
        expect(updatedSpeaker.image, 'https://example.com/new.jpg');
      });

      test('should return a new Speaker with all fields updated', () {
        const speaker = Speaker(
          name: 'John Doe',
          image: 'https://example.com/john.jpg',
        );
        final updatedSpeaker = speaker.copyWith(
          name: 'Jane Smith',
          image: 'https://example.com/jane.jpg',
        );

        expect(updatedSpeaker.name, 'Jane Smith');
        expect(updatedSpeaker.image, 'https://example.com/jane.jpg');
      });

      test('should keep original values when not specified in copyWith', () {
        const speaker = Speaker(
          name: 'John Doe',
          image: 'https://example.com/john.jpg',
        );
        final updatedSpeaker = speaker.copyWith();

        expect(updatedSpeaker.name, speaker.name);
        expect(updatedSpeaker.image, speaker.image);
      });
    });

    group('Equatable', () {
      test('should be equal when all properties are the same', () {
        const speaker1 = Speaker(
          name: 'John Doe',
          image: 'https://example.com/john.jpg',
        );
        const speaker2 = Speaker(
          name: 'John Doe',
          image: 'https://example.com/john.jpg',
        );

        expect(speaker1, equals(speaker2));
      });

      test('should not be equal when name is different', () {
        const speaker1 = Speaker(
          name: 'John Doe',
          image: 'https://example.com/john.jpg',
        );
        const speaker2 = Speaker(
          name: 'Jane Smith',
          image: 'https://example.com/john.jpg',
        );

        expect(speaker1, isNot(equals(speaker2)));
      });

      test('should not be equal when image is different', () {
        const speaker1 = Speaker(
          name: 'John Doe',
          image: 'https://example.com/john.jpg',
        );
        const speaker2 = Speaker(
          name: 'John Doe',
          image: 'https://example.com/different.jpg',
        );

        expect(speaker1, isNot(equals(speaker2)));
      });

      test('should have same hashCode when equal', () {
        const speaker1 = Speaker(
          name: 'John Doe',
          image: 'https://example.com/john.jpg',
        );
        const speaker2 = Speaker(
          name: 'John Doe',
          image: 'https://example.com/john.jpg',
        );

        expect(speaker1.hashCode, equals(speaker2.hashCode));
      });

      test('props should include all properties', () {
        const speaker = Speaker(
          name: 'John Doe',
          image: 'https://example.com/john.jpg',
        );

        expect(speaker.props, ['John Doe', 'https://example.com/john.jpg']);
      });
    });
  });
}
