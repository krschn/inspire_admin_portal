import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/snackbar_service.dart';
import '../../data/services/excel_parser_base.dart';
import '../../data/services/excel_parser_factory.dart';
import '../../domain/repositories/talk_repository.dart';
import '../../domain/usecases/batch_upload_talks.dart';
import 'events_provider.dart';
import 'selected_event_provider.dart';
import 'talks_provider.dart';

/// Notifier for the currently selected Excel format
class SelectedExcelFormatNotifier extends Notifier<ExcelFormat> {
  @override
  ExcelFormat build() => ExcelFormat.standard;

  void select(ExcelFormat format) {
    state = format;
  }
}

/// Provider for the currently selected Excel format
final selectedExcelFormatProvider =
    NotifierProvider<SelectedExcelFormatNotifier, ExcelFormat>(
        SelectedExcelFormatNotifier.new);

/// Provider for available Excel formats
final availableExcelFormatsProvider = Provider<List<ExcelFormat>>((ref) {
  return ExcelParserFactory.availableFormats;
});

/// Provider for the Excel parser based on selected format
final excelParserServiceProvider = Provider<ExcelParserBase>((ref) {
  final format = ref.watch(selectedExcelFormatProvider);
  return ExcelParserFactory.getParser(format);
});

final batchUploadTalksUseCaseProvider = Provider<BatchUploadTalks>((ref) {
  final repository = ref.watch(talkRepositoryProvider);
  return BatchUploadTalks(repository);
});

class ExcelUploadState {
  final bool isUploading;
  final BatchUploadResult? result;
  final List<ParseError>? parseErrors;

  const ExcelUploadState({
    this.isUploading = false,
    this.result,
    this.parseErrors,
  });

  ExcelUploadState copyWith({
    bool? isUploading,
    BatchUploadResult? result,
    List<ParseError>? parseErrors,
  }) {
    return ExcelUploadState(
      isUploading: isUploading ?? this.isUploading,
      result: result,
      parseErrors: parseErrors,
    );
  }
}

final excelUploadProvider =
    NotifierProvider<ExcelUploadNotifier, ExcelUploadState>(
        ExcelUploadNotifier.new);

class ExcelUploadNotifier extends Notifier<ExcelUploadState> {
  @override
  ExcelUploadState build() => const ExcelUploadState();

  Future<bool> uploadExcel(Uint8List bytes) async {
    final selectedEvent = ref.read(selectedEventProvider);
    if (selectedEvent == null) {
      SnackbarService.showError('Please select an event first');
      return false;
    }

    state = state.copyWith(isUploading: true);

    try {
      final parser = ref.read(excelParserServiceProvider);
      final parseResult = parser.parseExcel(bytes);

      if (parseResult.talks.isEmpty) {
        state = ExcelUploadState(
          parseErrors: parseResult.errors,
        );
        SnackbarService.showError('No valid talks found in Excel file');
        return false;
      }

      final batchUpload = ref.read(batchUploadTalksUseCaseProvider);
      final result = await batchUpload(selectedEvent.id, parseResult.talks);

      return result.fold(
        (failure) {
          state = const ExcelUploadState();
          SnackbarService.showError(failure.message);
          return false;
        },
        (uploadResult) {
          state = ExcelUploadState(
            result: uploadResult,
            parseErrors: parseResult.errors,
          );

          // Refresh talks list
          ref.read(talksProvider.notifier).refresh();

          return true;
        },
      );
    } catch (e) {
      state = const ExcelUploadState();
      SnackbarService.showError('Failed to parse Excel file: $e');
      return false;
    }
  }

  void clearState() {
    state = const ExcelUploadState();
  }
}
