import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/talk.dart';
import '../repositories/talk_repository.dart';

class UpdateTalk {
  final TalkRepository repository;

  UpdateTalk(this.repository);

  Future<Either<Failure, Talk>> call(String eventId, Talk talk) {
    return repository.updateTalk(eventId, talk);
  }
}
