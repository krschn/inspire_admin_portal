import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/snackbar_service.dart';
import '../../../talks/presentation/providers/selected_event_provider.dart';
import '../../data/services/track_excel_parser_base.dart';
import '../../data/services/track_excel_parser_factory.dart';
import '../../domain/repositories/track_repository.dart';
import '../../domain/usecases/batch_upload_tracks.dart';
import 'tracks_provider.dart';

/// Notifier for the currently selected Track Excel format
class SelectedTrackExcelFormatNotifier extends Notifier<TrackExcelFormat> {
  @override
  TrackExcelFormat build() => TrackExcelFormat.standard;

  void select(TrackExcelFormat format) {
    state = format;
  }
}

/// Provider for the currently selected Track Excel format
final selectedTrackExcelFormatProvider =
    NotifierProvider<SelectedTrackExcelFormatNotifier, TrackExcelFormat>(
        SelectedTrackExcelFormatNotifier.new);

/// Provider for available Track Excel formats
final availableTrackExcelFormatsProvider = Provider<List<TrackExcelFormat>>((ref) {
  return TrackExcelParserFactory.availableFormats;
});

/// Provider for the Track Excel parser based on selected format
final trackExcelParserServiceProvider = Provider<TrackExcelParserBase>((ref) {
  final format = ref.watch(selectedTrackExcelFormatProvider);
  return TrackExcelParserFactory.getParser(format);
});

final batchUploadTracksUseCaseProvider = Provider<BatchUploadTracks>((ref) {
  final repository = ref.watch(trackRepositoryProvider);
  return BatchUploadTracks(repository);
});

class TrackExcelUploadState {
  final bool isUploading;
  final TrackBatchUploadResult? result;
  final List<TrackParseError>? parseErrors;

  const TrackExcelUploadState({
    this.isUploading = false,
    this.result,
    this.parseErrors,
  });

  TrackExcelUploadState copyWith({
    bool? isUploading,
    TrackBatchUploadResult? result,
    List<TrackParseError>? parseErrors,
  }) {
    return TrackExcelUploadState(
      isUploading: isUploading ?? this.isUploading,
      result: result,
      parseErrors: parseErrors,
    );
  }
}

final trackExcelUploadProvider =
    NotifierProvider<TrackExcelUploadNotifier, TrackExcelUploadState>(
        TrackExcelUploadNotifier.new);

class TrackExcelUploadNotifier extends Notifier<TrackExcelUploadState> {
  @override
  TrackExcelUploadState build() => const TrackExcelUploadState();

  Future<bool> uploadExcel(Uint8List bytes) async {
    final selectedEvent = ref.read(selectedEventProvider);
    if (selectedEvent == null) {
      SnackbarService.showError('Please select an event first');
      return false;
    }

    state = state.copyWith(isUploading: true);

    try {
      final parser = ref.read(trackExcelParserServiceProvider);
      final parseResult = parser.parseExcel(bytes);

      if (parseResult.tracks.isEmpty) {
        state = TrackExcelUploadState(
          parseErrors: parseResult.errors,
        );
        SnackbarService.showError('No valid tracks found in Excel file');
        return false;
      }

      final batchUpload = ref.read(batchUploadTracksUseCaseProvider);
      final result = await batchUpload(selectedEvent.id, parseResult.tracks);

      return result.fold(
        (failure) {
          state = const TrackExcelUploadState();
          SnackbarService.showError(failure.message);
          return false;
        },
        (uploadResult) {
          state = TrackExcelUploadState(
            result: uploadResult,
            parseErrors: parseResult.errors,
          );

          // Refresh tracks list
          ref.read(tracksProvider.notifier).refresh();

          return true;
        },
      );
    } catch (e) {
      state = const TrackExcelUploadState();
      SnackbarService.showError('Failed to parse Excel file: $e');
      return false;
    }
  }

  void clearState() {
    state = const TrackExcelUploadState();
  }
}
