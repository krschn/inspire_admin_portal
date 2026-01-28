import 'package:equatable/equatable.dart';

class Track extends Equatable {
  final String? id;
  final int trackNumber;
  final String trackDescription;
  final String trackColor;

  const Track({
    this.id,
    required this.trackNumber,
    required this.trackDescription,
    required this.trackColor,
  });

  @override
  List<Object?> get props => [
        id,
        trackNumber,
        trackDescription,
        trackColor,
      ];

  Track copyWith({
    String? id,
    int? trackNumber,
    String? trackDescription,
    String? trackColor,
  }) {
    return Track(
      id: id ?? this.id,
      trackNumber: trackNumber ?? this.trackNumber,
      trackDescription: trackDescription ?? this.trackDescription,
      trackColor: trackColor ?? this.trackColor,
    );
  }
}
