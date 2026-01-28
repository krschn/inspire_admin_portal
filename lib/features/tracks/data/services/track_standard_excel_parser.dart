import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/track.dart';
import 'track_excel_parser_base.dart';

/// Standard Excel parser service for tracks.
///
/// Expected columns:
/// 0: track_number (int), 1: track_description (string), 2: track_color (hex string)
class TrackStandardExcelParser extends TrackExcelParserBase {
  static const _trackNumberColumn = 0;
  static const _trackDescriptionColumn = 1;
  static const _trackColorColumn = 2;

  // Default color palette for auto-assigned colors based on track number
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
    final List<Track> tracks = [];
    final List<TrackParseError> errors = [];

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
          final track = _parseRow(row, rowNumber);
          if (track != null) {
            tracks.add(track);
          }
        } on ParseException catch (e) {
          errors.add(TrackParseError(rowNumber: rowNumber, reason: e.message));
        }
      }

      return TrackExcelParseResult(tracks: tracks, errors: errors);
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

  int? _parseTrackNumber(List<Data?> row, int index) {
    if (index >= row.length || row[index] == null) {
      return null;
    }

    final cell = row[index]!;

    // Handle IntCellValue directly
    if (cell.value is IntCellValue) {
      return (cell.value as IntCellValue).value;
    }

    // Handle DoubleCellValue (Excel often stores integers as doubles)
    if (cell.value is DoubleCellValue) {
      return (cell.value as DoubleCellValue).value.toInt();
    }

    // Fallback to string parsing
    final strValue = cell.value?.toString().trim() ?? '';
    return int.tryParse(strValue);
  }

  bool _isValidHexColor(String color) {
    return RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(color);
  }

  Track? _parseRow(List<Data?> row, int rowNumber) {
    // Check if row is empty
    if (row.every(
      (cell) =>
          cell?.value == null || cell?.value.toString().trim().isEmpty == true,
    )) {
      return null;
    }

    final trackNumber = _parseTrackNumber(row, _trackNumberColumn);
    if (trackNumber == null) {
      throw const ParseException('Track number is required and must be an integer');
    }

    final description = _getCellValue(row, _trackDescriptionColumn);
    if (description.isEmpty) {
      throw const ParseException('Track description is required');
    }

    var color = _getCellValue(row, _trackColorColumn);
    if (color.isEmpty) {
      // Assign color from palette based on track number
      final colorIndex = (trackNumber - 1) % _colorPalette.length;
      color = _colorPalette[colorIndex];
    } else if (!_isValidHexColor(color)) {
      throw ParseException('Invalid color format: $color (expected #RRGGBB)');
    }

    return Track(
      trackNumber: trackNumber,
      trackDescription: description,
      trackColor: color,
    );
  }
}
