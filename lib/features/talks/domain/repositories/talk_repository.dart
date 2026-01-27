import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/event.dart';
import '../entities/talk.dart';

abstract class TalkRepository {
  Future<Either<Failure, List<Event>>> getEvents();

  Future<Either<Failure, List<Talk>>> getTalks(String eventId);

  Future<Either<Failure, Talk>> createTalk(String eventId, Talk talk);

  Future<Either<Failure, Talk>> updateTalk(String eventId, Talk talk);

  Future<Either<Failure, void>> deleteTalk(String eventId, String talkId);

  Future<Either<Failure, BatchUploadResult>> batchUploadTalks(
    String eventId,
    List<Talk> talks,
  );
}

class BatchUploadResult {
  final int createdCount;
  final int updatedCount;
  final List<SkippedRow> skippedRows;

  const BatchUploadResult({
    required this.createdCount,
    required this.updatedCount,
    required this.skippedRows,
  });
}

class SkippedRow {
  final int rowNumber;
  final String reason;

  const SkippedRow({
    required this.rowNumber,
    required this.reason,
  });
}
