import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/talk.dart';
import '../repositories/talk_repository.dart';

class CreateTalk {
  final TalkRepository repository;

  CreateTalk(this.repository);

  Future<Either<Failure, Talk>> call(String eventId, Talk talk) {
    return repository.createTalk(eventId, talk);
  }
}
