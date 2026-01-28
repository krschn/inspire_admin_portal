import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/track.dart';
import '../repositories/track_repository.dart';

class BatchUploadTracks {
  final TrackRepository repository;

  BatchUploadTracks(this.repository);

  Future<Either<Failure, TrackBatchUploadResult>> call(
    String eventId,
    List<Track> tracks,
  ) {
    return repository.batchUploadTracks(eventId, tracks);
  }
}
