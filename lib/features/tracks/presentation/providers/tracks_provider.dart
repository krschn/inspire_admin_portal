import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/utils/snackbar_service.dart';
import '../../../talks/presentation/providers/selected_event_provider.dart';
import '../../data/datasources/track_remote_datasource.dart';
import '../../data/repositories/track_repository_impl.dart';
import '../../domain/entities/track.dart';
import '../../domain/repositories/track_repository.dart';
import '../../domain/usecases/create_track.dart';
import '../../domain/usecases/delete_track.dart';
import '../../domain/usecases/get_tracks.dart';
import '../../domain/usecases/update_track.dart';

final trackRemoteDataSourceProvider = Provider<TrackRemoteDataSource>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return TrackRemoteDataSourceImpl(firestore);
});

final trackRepositoryProvider = Provider<TrackRepository>((ref) {
  final dataSource = ref.watch(trackRemoteDataSourceProvider);
  return TrackRepositoryImpl(dataSource);
});

final getTracksUseCaseProvider = Provider<GetTracks>((ref) {
  final repository = ref.watch(trackRepositoryProvider);
  return GetTracks(repository);
});

final createTrackUseCaseProvider = Provider<CreateTrack>((ref) {
  final repository = ref.watch(trackRepositoryProvider);
  return CreateTrack(repository);
});

final updateTrackUseCaseProvider = Provider<UpdateTrack>((ref) {
  final repository = ref.watch(trackRepositoryProvider);
  return UpdateTrack(repository);
});

final deleteTrackUseCaseProvider = Provider<DeleteTrack>((ref) {
  final repository = ref.watch(trackRepositoryProvider);
  return DeleteTrack(repository);
});

final tracksProvider =
    AsyncNotifierProvider<TracksNotifier, List<Track>>(TracksNotifier.new);

class TracksNotifier extends AsyncNotifier<List<Track>> {
  @override
  Future<List<Track>> build() async {
    final selectedEvent = ref.watch(selectedEventProvider);
    if (selectedEvent == null) {
      return [];
    }
    return _fetchTracks(selectedEvent.id);
  }

  Future<List<Track>> _fetchTracks(String eventId) async {
    final getTracks = ref.read(getTracksUseCaseProvider);
    final result = await getTracks(eventId);
    return result.fold(
      (failure) {
        _showError(failure);
        return [];
      },
      (tracks) => tracks,
    );
  }

  Future<void> refresh() async {
    final selectedEvent = ref.read(selectedEventProvider);
    if (selectedEvent == null) return;

    state = const AsyncLoading();
    state = AsyncData(await _fetchTracks(selectedEvent.id));
  }

  Future<bool> createTrack(Track track) async {
    final selectedEvent = ref.read(selectedEventProvider);
    if (selectedEvent == null) {
      SnackbarService.showError('Please select an event first');
      return false;
    }

    final createTrackUseCase = ref.read(createTrackUseCaseProvider);
    final result = await createTrackUseCase(selectedEvent.id, track);

    return result.fold(
      (failure) {
        _showError(failure);
        return false;
      },
      (createdTrack) {
        // Insert in sorted order by track number
        final currentTracks = <Track>[...state.value ?? [], createdTrack];
        currentTracks.sort((a, b) => a.trackNumber.compareTo(b.trackNumber));
        state = AsyncData(currentTracks);
        SnackbarService.showSuccess('Track created successfully');
        return true;
      },
    );
  }

  Future<bool> updateTrack(Track track) async {
    final selectedEvent = ref.read(selectedEventProvider);
    if (selectedEvent == null) {
      SnackbarService.showError('Please select an event first');
      return false;
    }

    final updateTrackUseCase = ref.read(updateTrackUseCaseProvider);
    final result = await updateTrackUseCase(selectedEvent.id, track);

    return result.fold(
      (failure) {
        _showError(failure);
        return false;
      },
      (updatedTrack) {
        final currentTracks = (state.value ?? [])
            .map((t) => t.id == updatedTrack.id ? updatedTrack : t)
            .toList();
        currentTracks.sort((a, b) => a.trackNumber.compareTo(b.trackNumber));
        state = AsyncData(currentTracks);
        SnackbarService.showSuccess('Track updated successfully');
        return true;
      },
    );
  }

  Future<bool> deleteTrack(String trackId) async {
    final selectedEvent = ref.read(selectedEventProvider);
    if (selectedEvent == null) {
      SnackbarService.showError('Please select an event first');
      return false;
    }

    final deleteTrackUseCase = ref.read(deleteTrackUseCaseProvider);
    final result = await deleteTrackUseCase(selectedEvent.id, trackId);

    return result.fold(
      (failure) {
        _showError(failure);
        return false;
      },
      (_) {
        state = AsyncData(
          (state.value ?? []).where((t) => t.id != trackId).toList(),
        );
        SnackbarService.showSuccess('Track deleted successfully');
        return true;
      },
    );
  }

  void _showError(Failure failure) {
    SnackbarService.showError(failure.message);
  }
}
