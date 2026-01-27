import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/talk.dart';
import '../../domain/repositories/talk_repository.dart';
import '../datasources/talk_remote_datasource.dart';
import '../models/talk_model.dart';

class TalkRepositoryImpl implements TalkRepository {
  final TalkRemoteDataSource remoteDataSource;

  TalkRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<Event>>> getEvents() async {
    try {
      final events = await remoteDataSource.getEvents();
      return Right(events.map((e) => e.toEntity()).toList());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Talk>>> getTalks(String eventId) async {
    try {
      final talks = await remoteDataSource.getTalks(eventId);
      return Right(talks.map((t) => t.toEntity()).toList());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Talk>> createTalk(String eventId, Talk talk) async {
    try {
      final talkModel = TalkModel.fromEntity(talk);
      final created = await remoteDataSource.createTalk(eventId, talkModel);
      return Right(created.toEntity());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Talk>> updateTalk(String eventId, Talk talk) async {
    try {
      final talkModel = TalkModel.fromEntity(talk);
      final updated = await remoteDataSource.updateTalk(eventId, talkModel);
      return Right(updated.toEntity());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTalk(
    String eventId,
    String talkId,
  ) async {
    try {
      await remoteDataSource.deleteTalk(eventId, talkId);
      return const Right(null);
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, BatchUploadResult>> batchUploadTalks(
    String eventId,
    List<Talk> talks,
  ) async {
    try {
      int createdCount = 0;
      int updatedCount = 0;
      final List<SkippedRow> skippedRows = [];

      for (int i = 0; i < talks.length; i++) {
        final talk = talks[i];
        final rowNumber = i + 2; // +2 for header row and 0-indexing

        try {
          final existingTalk = await remoteDataSource.findTalkByTitleAndDate(
            eventId,
            talk.title,
            talk.date,
          );

          if (existingTalk != null) {
            final updatedTalk = TalkModel.fromEntity(
              talk.copyWith(id: existingTalk.id),
            );
            await remoteDataSource.updateTalk(eventId, updatedTalk);
            updatedCount++;
          } else {
            final newTalk = TalkModel.fromEntity(talk);
            await remoteDataSource.createTalk(eventId, newTalk);
            createdCount++;
          }
        } on ServerException catch (e) {
          skippedRows.add(SkippedRow(
            rowNumber: rowNumber,
            reason: e.message,
          ));
        }
      }

      return Right(BatchUploadResult(
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
