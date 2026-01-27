import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/event.dart';
import '../repositories/talk_repository.dart';

class GetEvents {
  final TalkRepository repository;

  GetEvents(this.repository);

  Future<Either<Failure, List<Event>>> call() {
    return repository.getEvents();
  }
}
