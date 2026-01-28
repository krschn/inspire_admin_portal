import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/track.dart';
import 'track_excel_parser_base.dart';

/// Excel parser service for extracting tracks from DDD 2025 talks Excel.
///
/// Reads the Track column (column 6) and extracts unique tracks.
/// Expected format: "Track N - Description" (e.g., "Track 7 - Data & Analytics")
class TrackDddExcelParser extends TrackExcelParserBase {
  static const _trackColumn = 6;

  // Default color palette for auto-assigned colors
  static const _colorPalette = [
    '#2E6CA4', // Blue
    '#4CAF50', // Green
    '#FF9800', // Orange
    '#9C27B0', // Purple
    '#E91E63', // Pink
    '#00BCD4', // Cyan
    '#795548', // Brown
    '#607D8B', // Blue Grey
    '#F44336', // Red
    '#3F51B5', // Indigo
  ];

  @override
  TrackExcelParseResult parseExcel(Uint8List bytes) {
    final List<TrackParseError> errors = [];
    final Map<int, Track> uniqueTracks = {};
    int skippedRows = 0;

    try {
      final excel = Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        throw const ParseException('Excel file has no sheets');
      }

      final sheet = excel.tables[excel.tables.keys.first]!;
      final rows = sheet.rows;

      if (rows.length < 2) {
        throw const ParseException(
          'Excel file must have a header row and at least one data row',
        );
      }

      // Skip header row, start from index 1
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        final rowNumber = i + 1; // Human-readable row number

        try {
          final trackInfo = _parseTrackFromRow(row);
          if (trackInfo == null) {
            skippedRows++;
            continue;
          }

          final (trackNumber, description) = trackInfo;

          // Only add if we haven't seen this track number before
          if (!uniqueTracks.containsKey(trackNumber)) {
            final colorIndex = (trackNumber - 1) % _colorPalette.length;
            uniqueTracks[trackNumber] = Track(
              trackNumber: trackNumber,
              trackDescription: description,
              trackColor: _colorPalette[colorIndex],
            );
          }
        } on ParseException catch (e) {
          errors.add(TrackParseError(rowNumber: rowNumber, reason: e.message));
        }
      }

      // Sort tracks by track number
      final sortedTracks = uniqueTracks.values.toList()
        ..sort((a, b) => a.trackNumber.compareTo(b.trackNumber));

      return TrackExcelParseResult(
        tracks: sortedTracks,
        errors: errors,
        skippedRows: skippedRows,
      );
    } on ParseException {
      rethrow;
    } catch (e) {
      throw ParseException('Failed to parse Excel file: $e');
    }
  }

  String _getCellValue(List<Data?> row, int index) {
    if (index >= row.length || row[index] == null) {
      return '';
    }
    return row[index]!.value?.toString().trim() ?? '';
  }

  /// Parse track info from a row, returns (trackNumber, description) or null if empty
  (int, String)? _parseTrackFromRow(List<Data?> row) {
    // Check if row is empty
    if (row.every(
      (cell) =>
          cell?.value == null || cell?.value.toString().trim().isEmpty == true,
    )) {
      return null;
    }

    final trackStr = _getCellValue(row, _trackColumn);
    if (trackStr.isEmpty) {
      return null;
    }

    // Parse "Track N - Description" format
    final trackMatch = RegExp(r'Track\s*(\d+)\s*[-:]\s*(.+)', caseSensitive: false)
        .firstMatch(trackStr);

    if (trackMatch != null) {
      final trackNumber = int.tryParse(trackMatch.group(1)!);
      final description = trackMatch.group(2)!.trim();

      if (trackNumber != null && description.isNotEmpty) {
        return (trackNumber, description);
      }
    }

    // Fallback: try parsing just "Track N" format
    final simpleMatch = RegExp(r'Track\s*(\d+)', caseSensitive: false)
        .firstMatch(trackStr);

    if (simpleMatch != null) {
      final trackNumber = int.tryParse(simpleMatch.group(1)!);
      if (trackNumber != null) {
        return (trackNumber, 'Track $trackNumber');
      }
    }

    return null;
  }
}
