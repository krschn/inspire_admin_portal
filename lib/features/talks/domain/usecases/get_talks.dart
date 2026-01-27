import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/talk.dart';
import '../repositories/talk_repository.dart';

class GetTalks {
  final TalkRepository repository;

  GetTalks(this.repository);

  Future<Either<Failure, List<Talk>>> call(String eventId) {
    return repository.getTalks(eventId);
  }
}
