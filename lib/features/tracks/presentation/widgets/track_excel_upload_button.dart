import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/track_excel_parser_base.dart';
import '../providers/track_excel_upload_provider.dart';
import 'track_upload_summary_dialog.dart';

class TrackExcelUploadButton extends ConsumerWidget {
  const TrackExcelUploadButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadState = ref.watch(trackExcelUploadProvider);

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
    final selectedFormat = await _showFormatSelectionDialog(context, ref);
    if (selectedFormat == null) return;

    // Set the selected format
    ref.read(selectedTrackExcelFormatProvider.notifier).select(selectedFormat);

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    final success = await ref
        .read(trackExcelUploadProvider.notifier)
        .uploadExcel(file.bytes!);

    if (context.mounted && success) {
      final uploadState = ref.read(trackExcelUploadProvider);
      await showDialog(
        context: context,
        builder: (context) => TrackUploadSummaryDialog(
          result: uploadState.result,
          parseErrors: uploadState.parseErrors,
        ),
      );
      ref.read(trackExcelUploadProvider.notifier).clearState();
    }
  }

  Future<TrackExcelFormat?> _showFormatSelectionDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final formats = ref.read(availableTrackExcelFormatsProvider);

    return showDialog<TrackExcelFormat>(
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
