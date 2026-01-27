import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../data/datasources/talk_remote_datasource.dart';
import '../../data/repositories/talk_repository_impl.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/talk_repository.dart';
import '../../domain/usecases/get_events.dart';

final talkRemoteDataSourceProvider = Provider<TalkRemoteDataSource>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return TalkRemoteDataSourceImpl(firestore);
});

final talkRepositoryProvider = Provider<TalkRepository>((ref) {
  final dataSource = ref.watch(talkRemoteDataSourceProvider);
  return TalkRepositoryImpl(dataSource);
});

final getEventsUseCaseProvider = Provider<GetEvents>((ref) {
  final repository = ref.watch(talkRepositoryProvider);
  return GetEvents(repository);
});

final eventsProvider = FutureProvider<List<Event>>((ref) async {
  final getEvents = ref.watch(getEventsUseCaseProvider);
  final result = await getEvents();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (events) => events,
  );
});
