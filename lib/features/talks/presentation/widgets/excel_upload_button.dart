import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/excel_upload_provider.dart';
import 'upload_summary_dialog.dart';

class ExcelUploadButton extends ConsumerWidget {
  const ExcelUploadButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadState = ref.watch(excelUploadProvider);

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
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    final success = await ref
        .read(excelUploadProvider.notifier)
        .uploadExcel(file.bytes!);

    if (context.mounted && success) {
      final uploadState = ref.read(excelUploadProvider);
      await showDialog(
        context: context,
        builder: (context) => UploadSummaryDialog(
          result: uploadState.result,
          parseErrors: uploadState.parseErrors,
        ),
      );
      ref.read(excelUploadProvider.notifier).clearState();
    }
  }
}
