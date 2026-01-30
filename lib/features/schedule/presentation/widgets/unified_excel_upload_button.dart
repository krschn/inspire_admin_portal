import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/snackbar_service.dart';
import '../../../talks/data/services/excel_parser_base.dart';
import '../../../talks/data/services/excel_parser_factory.dart';
import '../../../talks/domain/usecases/batch_upload_talks.dart';
import '../../../talks/presentation/providers/events_provider.dart';
import '../../../talks/presentation/providers/selected_event_provider.dart';
import '../../../talks/presentation/providers/talks_provider.dart';
import '../../../tracks/data/services/track_excel_parser_base.dart';
import '../../../tracks/data/services/track_excel_parser_factory.dart';
import '../../../tracks/presentation/providers/track_excel_upload_provider.dart';
import '../../../tracks/presentation/providers/tracks_provider.dart';

/// State for the unified excel upload
class UnifiedExcelUploadState {
  final bool isUploading;
  final int? talksUploaded;
  final int? tracksUploaded;
  final List<String>? errors;

  const UnifiedExcelUploadState({
    this.isUploading = false,
    this.talksUploaded,
    this.tracksUploaded,
    this.errors,
  });

  UnifiedExcelUploadState copyWith({
    bool? isUploading,
    int? talksUploaded,
    int? tracksUploaded,
    List<String>? errors,
  }) {
    return UnifiedExcelUploadState(
      isUploading: isUploading ?? this.isUploading,
      talksUploaded: talksUploaded ?? this.talksUploaded,
      tracksUploaded: tracksUploaded ?? this.tracksUploaded,
      errors: errors ?? this.errors,
    );
  }
}

/// Provider for the unified excel upload state
final unifiedExcelUploadProvider =
    NotifierProvider<UnifiedExcelUploadNotifier, UnifiedExcelUploadState>(
        UnifiedExcelUploadNotifier.new);

class UnifiedExcelUploadNotifier extends Notifier<UnifiedExcelUploadState> {
  @override
  UnifiedExcelUploadState build() => const UnifiedExcelUploadState();

  Future<bool> uploadExcel(Uint8List bytes, ExcelFormat format) async {
    final selectedEvent = ref.read(selectedEventProvider);
    if (selectedEvent == null) {
      SnackbarService.showError('Please select an event first');
      return false;
    }

    state = state.copyWith(isUploading: true);
    final errors = <String>[];

    try {
      // Parse and upload talks
      final talkParser = ExcelParserFactory.getParser(format);
      final talkParseResult = talkParser.parseExcel(bytes);

      int talksUploaded = 0;
      if (talkParseResult.talks.isNotEmpty) {
        final repository = ref.read(talkRepositoryProvider);
        final batchUpload = BatchUploadTalks(repository);
        final result = await batchUpload(selectedEvent.id, talkParseResult.talks);
        result.fold(
          (failure) => errors.add('Talks upload failed: ${failure.message}'),
          (uploadResult) => talksUploaded = uploadResult.createdCount + uploadResult.updatedCount,
        );
      }

      // Add talk parsing errors
      for (final error in talkParseResult.errors) {
        errors.add('Talk row ${error.rowNumber}: ${error.reason}');
      }

      // Parse and upload tracks
      final trackFormat = format == ExcelFormat.ddd2025
          ? TrackExcelFormat.ddd2025
          : TrackExcelFormat.standard;
      final trackParser = TrackExcelParserFactory.getParser(trackFormat);
      final trackParseResult = trackParser.parseExcel(bytes);

      int tracksUploaded = 0;
      if (trackParseResult.tracks.isNotEmpty) {
        final batchUpload = ref.read(batchUploadTracksUseCaseProvider);
        final result = await batchUpload(selectedEvent.id, trackParseResult.tracks);
        result.fold(
          (failure) => errors.add('Tracks upload failed: ${failure.message}'),
          (uploadResult) => tracksUploaded = uploadResult.createdCount + uploadResult.updatedCount,
        );
      }

      // Add track parsing errors (but these are often expected when no tracks sheet)
      for (final error in trackParseResult.errors) {
        if (!error.reason.contains('not found')) {
          errors.add('Track row ${error.rowNumber}: ${error.reason}');
        }
      }

      state = UnifiedExcelUploadState(
        talksUploaded: talksUploaded,
        tracksUploaded: tracksUploaded,
        errors: errors.isEmpty ? null : errors,
      );

      // Refresh both providers
      ref.read(talksProvider.notifier).refresh();
      ref.read(tracksProvider.notifier).refresh();

      return true;
    } catch (e) {
      state = const UnifiedExcelUploadState();
      SnackbarService.showError('Failed to parse Excel file: $e');
      return false;
    }
  }

  void clearState() {
    state = const UnifiedExcelUploadState();
  }
}

class UnifiedExcelUploadButton extends ConsumerWidget {
  const UnifiedExcelUploadButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadState = ref.watch(unifiedExcelUploadProvider);

    return FilledButton.tonalIcon(
      onPressed: uploadState.isUploading
          ? null
          : () => _pickAndUpload(context, ref),
      icon: uploadState.isUploading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.upload_file),
      label: Text(uploadState.isUploading ? 'Uploading...' : 'Upload Excel'),
    );
  }

  Future<void> _pickAndUpload(BuildContext context, WidgetRef ref) async {
    // Show format selection dialog first
    final selectedFormat = await _showFormatSelectionDialog(context);
    if (selectedFormat == null) return;

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    final success = await ref
        .read(unifiedExcelUploadProvider.notifier)
        .uploadExcel(file.bytes!, selectedFormat);

    if (context.mounted && success) {
      final uploadState = ref.read(unifiedExcelUploadProvider);
      await showDialog(
        context: context,
        builder: (context) => _UnifiedUploadSummaryDialog(state: uploadState),
      );
      ref.read(unifiedExcelUploadProvider.notifier).clearState();
    }
  }

  Future<ExcelFormat?> _showFormatSelectionDialog(BuildContext context) async {
    final formats = ExcelParserFactory.availableFormats;

    return showDialog<ExcelFormat>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Excel Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: formats
              .map(
                (format) => ListTile(
                  title: Text(format.displayName),
                  subtitle: Text(format.description),
                  onTap: () => Navigator.of(context).pop(format),
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class _UnifiedUploadSummaryDialog extends StatelessWidget {
  final UnifiedExcelUploadState state;

  const _UnifiedUploadSummaryDialog({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Upload Summary'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultRow(
            context,
            icon: Icons.mic,
            label: 'Talks uploaded',
            count: state.talksUploaded ?? 0,
          ),
          const SizedBox(height: 8),
          _buildResultRow(
            context,
            icon: Icons.category,
            label: 'Tracks uploaded',
            count: state.tracksUploaded ?? 0,
          ),
          if (state.errors != null && state.errors!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Warnings/Errors:',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 150),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: state.errors!
                      .take(10) // Show max 10 errors
                      .map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              e,
                              style: theme.textTheme.bodySmall,
                              softWrap: true,
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
            if (state.errors!.length > 10)
              Text(
                '...and ${state.errors!.length - 10} more',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }

  Widget _buildResultRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int count,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(label),
        const Spacer(),
        Text(
          count.toString(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: count > 0 ? theme.colorScheme.primary : null,
          ),
        ),
      ],
    );
  }
}
