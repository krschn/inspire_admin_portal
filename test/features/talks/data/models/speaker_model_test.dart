import 'package:flutter_test/flutter_test.dart';
import 'package:inspire_admin_portal/features/talks/data/models/speaker_model.dart';
import 'package:inspire_admin_portal/features/talks/domain/entities/speaker.dart';

void main() {
  group('SpeakerModel', () {
    group('fromMap', () {
      test('should create SpeakerModel from valid map', () {
        final map = {
          'name': 'John Doe',
          'image': 'https://example.com/john.jpg',
        };

        final model = SpeakerModel.fromMap(map);

        expect(model.name, 'John Doe');
        expect(model.image, 'https://example.com/john.jpg');
      });

      test('should use empty string when name is null', () {
        final map = {
          'name': null,
          'image': 'https://example.com/john.jpg',
        };

        final model = SpeakerModel.fromMap(map);

        expect(model.name, '');
        expect(model.image, 'https://example.com/john.jpg');
      });

      test('should use empty string when image is null', () {
        final map = {
          'name': 'John Doe',
          'image': null,
        };

        final model = SpeakerModel.fromMap(map);

        expect(model.name, 'John Doe');
        expect(model.image, '');
      });

      test('should use empty strings when keys are missing', () {
        final Map<String, dynamic> map = {};

        final model = SpeakerModel.fromMap(map);

        expect(model.name, '');
        expect(model.image, '');
      });
    });

    group('fromEntity', () {
      test('should create SpeakerModel from Speaker entity', () {
        const speaker = Speaker(
          name: 'Jane Smith',
          image: 'https://example.com/jane.jpg',
        );

        final model = SpeakerModel.fromEntity(speaker);

        expect(model.name, 'Jane Smith');
        expect(model.image, 'https://example.com/jane.jpg');
      });

      test('should preserve empty values from entity', () {
        const speaker = Speaker(
          name: '',
          image: '',
        );

        final model = SpeakerModel.fromEntity(speaker);

        expect(model.name, '');
        expect(model.image, '');
      });
    });

    group('toMap', () {
      test('should convert SpeakerModel to map', () {
        const model = SpeakerModel(
          name: 'John Doe',
          image: 'https://example.com/john.jpg',
        );

        final map = model.toMap();

        expect(map, {
          'name': 'John Doe',
          'image': 'https://example.com/john.jpg',
        });
      });

      test('should include empty strings in map', () {
        const model = SpeakerModel(
          name: '',
          image: '',
        );

        final map = model.toMap();

        expect(map, {
          'name': '',
          'image': '',
        });
      });
    });

    group('toEntity', () {
      test('should convert SpeakerModel to Speaker entity', () {
        const model = SpeakerModel(
          name: 'John Doe',
          image: 'https://example.com/john.jpg',
        );

        final entity = model.toEntity();

        expect(entity, isA<Speaker>());
        expect(entity.name, 'John Doe');
        expect(entity.image, 'https://example.com/john.jpg');
      });
    });

    group('round-trip conversion', () {
      test('should preserve data through entity -> model -> map -> model -> entity', () {
        const originalEntity = Speaker(
          name: 'Test Speaker',
          image: 'https://example.com/test.jpg',
        );

        final model1 = SpeakerModel.fromEntity(originalEntity);
        final map = model1.toMap();
        final model2 = SpeakerModel.fromMap(map);
        final finalEntity = model2.toEntity();

        expect(finalEntity, equals(originalEntity));
      });
    });
  });
}
