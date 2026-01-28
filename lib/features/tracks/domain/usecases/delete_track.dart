import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/track_repository.dart';

class DeleteTrack {
  final TrackRepository repository;

  DeleteTrack(this.repository);

  Future<Either<Failure, void>> call(String eventId, String trackId) {
    return repository.deleteTrack(eventId, trackId);
  }
}
