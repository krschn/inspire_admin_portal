import '../../domain/entities/speaker.dart';

class SpeakerModel extends Speaker {
  const SpeakerModel({
    required super.name,
    required super.image,
  });

  factory SpeakerModel.fromMap(Map<String, dynamic> map) {
    return SpeakerModel(
      name: map['name'] as String? ?? '',
      image: map['image'] as String? ?? '',
    );
  }

  factory SpeakerModel.fromEntity(Speaker speaker) {
    return SpeakerModel(
      name: speaker.name,
      image: speaker.image,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'image': image,
    };
  }

  Speaker toEntity() {
    return Speaker(
      name: name,
      image: image,
    );
  }
}
