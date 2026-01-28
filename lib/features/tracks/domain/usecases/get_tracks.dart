import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/track.dart';
import '../repositories/track_repository.dart';

class GetTracks {
  final TrackRepository repository;

  GetTracks(this.repository);

  Future<Either<Failure, List<Track>>> call(String eventId) {
    return repository.getTracks(eventId);
  }
}
