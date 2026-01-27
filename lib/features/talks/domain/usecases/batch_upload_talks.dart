import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/talk.dart';
import '../repositories/talk_repository.dart';

class BatchUploadTalks {
  final TalkRepository repository;

  BatchUploadTalks(this.repository);

  Future<Either<Failure, BatchUploadResult>> call(
    String eventId,
    List<Talk> talks,
  ) {
    return repository.batchUploadTalks(eventId, talks);
  }
}
