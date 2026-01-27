import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/talk.dart';
import '../../domain/entities/speaker.dart';
import 'speaker_model.dart';

class TalkModel extends Talk {
  const TalkModel({
    super.id,
    required super.date,
    required super.title,
    required super.description,
    required super.speakers,
    required super.liveLink,
    required super.duration,
    required super.track,
    required super.venue,
  });

  factory TalkModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TalkModel(
      id: doc.id,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      speakers: _parseSpeakers(data['speakers']),
      liveLink: data['live_link'] as String? ?? '',
      duration: data['duration'] as String? ?? '',
      track: data['track'] as String? ?? '',
      venue: data['venue'] as String? ?? '',
    );
  }

  factory TalkModel.fromEntity(Talk talk) {
    return TalkModel(
      id: talk.id,
      date: talk.date,
      title: talk.title,
      description: talk.description,
      speakers: talk.speakers,
      liveLink: talk.liveLink,
      duration: talk.duration,
      track: talk.track,
      venue: talk.venue,
    );
  }

  static List<Speaker> _parseSpeakers(dynamic speakersData) {
    if (speakersData == null) return [];
    if (speakersData is! List) return [];

    return speakersData
        .whereType<Map<String, dynamic>>()
        .map((map) => SpeakerModel.fromMap(map).toEntity())
        .toList();
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      'title': title,
      'description': description,
      'speakers': speakers
          .map((s) => SpeakerModel.fromEntity(s).toMap())
          .toList(),
      'live_link': liveLink,
      'duration': duration,
      'track': track,
      'venue': venue,
    };
  }

  Talk toEntity() {
    return Talk(
      id: id,
      date: date,
      title: title,
      description: description,
      speakers: speakers,
      liveLink: liveLink,
      duration: duration,
      track: track,
      venue: venue,
    );
  }
}
