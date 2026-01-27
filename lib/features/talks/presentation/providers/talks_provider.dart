import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/snackbar_service.dart';
import '../../domain/entities/talk.dart';
import '../../domain/usecases/create_talk.dart';
import '../../domain/usecases/delete_talk.dart';
import '../../domain/usecases/get_talks.dart';
import '../../domain/usecases/update_talk.dart';
import 'events_provider.dart';
import 'selected_event_provider.dart';

final getTalksUseCaseProvider = Provider<GetTalks>((ref) {
  final repository = ref.watch(talkRepositoryProvider);
  return GetTalks(repository);
});

final createTalkUseCaseProvider = Provider<CreateTalk>((ref) {
  final repository = ref.watch(talkRepositoryProvider);
  return CreateTalk(repository);
});

final updateTalkUseCaseProvider = Provider<UpdateTalk>((ref) {
  final repository = ref.watch(talkRepositoryProvider);
  return UpdateTalk(repository);
});

final deleteTalkUseCaseProvider = Provider<DeleteTalk>((ref) {
  final repository = ref.watch(talkRepositoryProvider);
  return DeleteTalk(repository);
});

final talksProvider =
    AsyncNotifierProvider<TalksNotifier, List<Talk>>(TalksNotifier.new);

class TalksNotifier extends AsyncNotifier<List<Talk>> {
  @override
  Future<List<Talk>> build() async {
    final selectedEvent = ref.watch(selectedEventProvider);
    if (selectedEvent == null) {
      return [];
    }
    return _fetchTalks(selectedEvent.id);
  }

  Future<List<Talk>> _fetchTalks(String eventId) async {
    final getTalks = ref.read(getTalksUseCaseProvider);
    final result = await getTalks(eventId);
    return result.fold(
      (failure) {
        _showError(failure);
        return [];
      },
      (talks) => talks,
    );
  }

  Future<void> refresh() async {
    final selectedEvent = ref.read(selectedEventProvider);
    if (selectedEvent == null) return;

    state = const AsyncLoading();
    state = AsyncData(await _fetchTalks(selectedEvent.id));
  }

  Future<bool> createTalk(Talk talk) async {
    final selectedEvent = ref.read(selectedEventProvider);
    if (selectedEvent == null) {
      SnackbarService.showError('Please select an event first');
      return false;
    }

    final createTalkUseCase = ref.read(createTalkUseCaseProvider);
    final result = await createTalkUseCase(selectedEvent.id, talk);

    return result.fold(
      (failure) {
        _showError(failure);
        return false;
      },
      (createdTalk) {
        state = AsyncData([...state.value ?? [], createdTalk]);
        SnackbarService.showSuccess('Talk created successfully');
        return true;
      },
    );
  }

  Future<bool> updateTalk(Talk talk) async {
    final selectedEvent = ref.read(selectedEventProvider);
    if (selectedEvent == null) {
      SnackbarService.showError('Please select an event first');
      return false;
    }

    final updateTalkUseCase = ref.read(updateTalkUseCaseProvider);
    final result = await updateTalkUseCase(selectedEvent.id, talk);

    return result.fold(
      (failure) {
        _showError(failure);
        return false;
      },
      (updatedTalk) {
        state = AsyncData(
          (state.value ?? [])
              .map((t) => t.id == updatedTalk.id ? updatedTalk : t)
              .toList(),
        );
        SnackbarService.showSuccess('Talk updated successfully');
        return true;
      },
    );
  }

  Future<bool> deleteTalk(String talkId) async {
    final selectedEvent = ref.read(selectedEventProvider);
    if (selectedEvent == null) {
      SnackbarService.showError('Please select an event first');
      return false;
    }

    final deleteTalkUseCase = ref.read(deleteTalkUseCaseProvider);
    final result = await deleteTalkUseCase(selectedEvent.id, talkId);

    return result.fold(
      (failure) {
        _showError(failure);
        return false;
      },
      (_) {
        state = AsyncData(
          (state.value ?? []).where((t) => t.id != talkId).toList(),
        );
        SnackbarService.showSuccess('Talk deleted successfully');
        return true;
      },
    );
  }

  void _showError(Failure failure) {
    SnackbarService.showError(failure.message);
  }
}
