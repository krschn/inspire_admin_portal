import 'package:equatable/equatable.dart';

import 'speaker.dart';

class Talk extends Equatable {
  final String? id;
  final DateTime date;
  final String title;
  final String description;
  final List<Speaker> speakers;
  final String liveLink;
  final String duration;
  final int track;
  final String venue;

  const Talk({
    this.id,
    required this.date,
    required this.title,
    required this.description,
    required this.speakers,
    required this.liveLink,
    required this.duration,
    required this.track,
    required this.venue,
  });

  @override
  List<Object?> get props => [
    id,
    date,
    title,
    description,
    speakers,
    liveLink,
    duration,
    track,
    venue,
  ];

  Talk copyWith({
    String? id,
    DateTime? date,
    String? title,
    String? description,
    List<Speaker>? speakers,
    String? liveLink,
    String? duration,
    int? track,
    String? venue,
  }) {
    return Talk(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      description: description ?? this.description,
      speakers: speakers ?? this.speakers,
      liveLink: liveLink ?? this.liveLink,
      duration: duration ?? this.duration,
      track: track ?? this.track,
      venue: venue ?? this.venue,
    );
  }
}
