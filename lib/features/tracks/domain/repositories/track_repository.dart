import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/track.dart';

abstract class TrackRepository {
  Future<Either<Failure, List<Track>>> getTracks(String eventId);

  Future<Either<Failure, Track>> createTrack(String eventId, Track track);

  Future<Either<Failure, Track>> updateTrack(String eventId, Track track);

  Future<Either<Failure, void>> deleteTrack(String eventId, String trackId);

  Future<Either<Failure, TrackBatchUploadResult>> batchUploadTracks(
    String eventId,
    List<Track> tracks,
  );
}

class TrackBatchUploadResult {
  final int createdCount;
  final int updatedCount;
  final List<TrackSkippedRow> skippedRows;

  const TrackBatchUploadResult({
    required this.createdCount,
    required this.updatedCount,
    required this.skippedRows,
  });
}

class TrackSkippedRow {
  final int rowNumber;
  final String reason;

  const TrackSkippedRow({
    required this.rowNumber,
    required this.reason,
  });
}
