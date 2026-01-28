import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/track.dart';
import '../../domain/repositories/track_repository.dart';
import '../datasources/track_remote_datasource.dart';
import '../models/track_model.dart';

class TrackRepositoryImpl implements TrackRepository {
  final TrackRemoteDataSource remoteDataSource;

  TrackRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<Track>>> getTracks(String eventId) async {
    try {
      final tracks = await remoteDataSource.getTracks(eventId);
      return Right(tracks.map((t) => t.toEntity()).toList());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Track>> createTrack(String eventId, Track track) async {
    try {
      final trackModel = TrackModel.fromEntity(track);
      final created = await remoteDataSource.createTrack(eventId, trackModel);
      return Right(created.toEntity());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Track>> updateTrack(String eventId, Track track) async {
    try {
      final trackModel = TrackModel.fromEntity(track);
      final updated = await remoteDataSource.updateTrack(eventId, trackModel);
      return Right(updated.toEntity());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTrack(
    String eventId,
    String trackId,
  ) async {
    try {
      await remoteDataSource.deleteTrack(eventId, trackId);
      return const Right(null);
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, TrackBatchUploadResult>> batchUploadTracks(
    String eventId,
    List<Track> tracks,
  ) async {
    try {
      int createdCount = 0;
      int updatedCount = 0;
      final List<TrackSkippedRow> skippedRows = [];

      for (int i = 0; i < tracks.length; i++) {
        final track = tracks[i];
        final rowNumber = i + 2; // +2 for header row and 0-indexing

        try {
          final existingTrack = await remoteDataSource.findTrackByNumber(
            eventId,
            track.trackNumber,
          );

          if (existingTrack != null) {
            final updatedTrack = TrackModel.fromEntity(
              track.copyWith(id: existingTrack.id),
            );
            await remoteDataSource.updateTrack(eventId, updatedTrack);
            updatedCount++;
          } else {
            final newTrack = TrackModel.fromEntity(track);
            await remoteDataSource.createTrack(eventId, newTrack);
            createdCount++;
          }
        } on ServerException catch (e) {
          skippedRows.add(TrackSkippedRow(
            rowNumber: rowNumber,
            reason: e.message,
          ));
        }
      }

      return Right(TrackBatchUploadResult(
        createdCount: createdCount,
        updatedCount: updatedCount,
        skippedRows: skippedRows,
      ));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
