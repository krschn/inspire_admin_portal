import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/talk_repository.dart';

class DeleteTalk {
  final TalkRepository repository;

  DeleteTalk(this.repository);

  Future<Either<Failure, void>> call(String eventId, String talkId) {
    return repository.deleteTalk(eventId, talkId);
  }
}
