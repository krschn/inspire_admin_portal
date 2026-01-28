import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/track.dart';

class TrackModel extends Track {
  const TrackModel({
    super.id,
    required super.trackNumber,
    required super.trackDescription,
    required super.trackColor,
  });

  factory TrackModel.fromEntity(Track track) {
    return TrackModel(
      id: track.id,
      trackNumber: track.trackNumber,
      trackDescription: track.trackDescription,
      trackColor: track.trackColor,
    );
  }

  factory TrackModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TrackModel(
      id: doc.id,
      trackNumber: data['track_number'] as int? ?? 0,
      trackDescription: data['track_description'] as String? ?? '',
      trackColor: data['track_color'] as String? ?? '#2E6CA4',
    );
  }

  Track toEntity() {
    return Track(
      id: id,
      trackNumber: trackNumber,
      trackDescription: trackDescription,
      trackColor: trackColor,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'track_number': trackNumber,
      'track_description': trackDescription,
      'track_color': trackColor,
    };
  }
}
