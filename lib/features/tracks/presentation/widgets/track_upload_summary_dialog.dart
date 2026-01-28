import 'package:flutter/material.dart';

import '../../data/services/track_excel_parser_base.dart';
import '../../domain/repositories/track_repository.dart';

class TrackUploadSummaryDialog extends StatelessWidget {
  final TrackBatchUploadResult? result;
  final List<TrackParseError>? parseErrors;

  const TrackUploadSummaryDialog({super.key, this.result, this.parseErrors});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasErrors =
        (result?.skippedRows.isNotEmpty ?? false) ||
        (parseErrors?.isNotEmpty ?? false);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            hasErrors ? Icons.warning_amber : Icons.check_circle,
            color: hasErrors
                ? theme.colorScheme.error
                : theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Text('Upload Summary'),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
        child: SelectionArea(
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (result != null) ...[
                _buildStatRow(
                  context,
                  Icons.add_circle,
                  'Created',
                  result!.createdCount.toString(),
                  theme.colorScheme.primary,
                ),
                const SizedBox(height: 8),
                _buildStatRow(
                  context,
                  Icons.edit,
                  'Updated',
                  result!.updatedCount.toString(),
                  theme.colorScheme.tertiary,
                ),
                if (result!.skippedRows.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Upload Errors (${result!.skippedRows.length})',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...result!.skippedRows.map(
                    (row) => _buildErrorRow(
                      context,
                      'Row ${row.rowNumber}',
                      row.reason,
                    ),
                  ),
                ],
              ],
              if (parseErrors != null && parseErrors!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Parse Errors (${parseErrors!.length})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                ...parseErrors!.map(
                  (error) => _buildErrorRow(
                    context,
                    'Row ${error.rowNumber}',
                    error.reason,
                  ),
                ),
              ],
            ],
          ),
        ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }

  Widget _buildErrorRow(BuildContext context, String row, String reason) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              row,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(reason, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(label),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
