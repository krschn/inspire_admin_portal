import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/track.dart';
import '../repositories/track_repository.dart';

class CreateTrack {
  final TrackRepository repository;

  CreateTrack(this.repository);

  Future<Either<Failure, Track>> call(String eventId, Track track) {
    return repository.createTrack(eventId, track);
  }
}
