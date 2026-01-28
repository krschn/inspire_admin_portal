import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/track.dart';
import '../repositories/track_repository.dart';

class UpdateTrack {
  final TrackRepository repository;

  UpdateTrack(this.repository);

  Future<Either<Failure, Track>> call(String eventId, Track track) {
    return repository.updateTrack(eventId, track);
  }
}
