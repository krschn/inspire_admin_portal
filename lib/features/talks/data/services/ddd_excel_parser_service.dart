import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/speaker.dart';
import '../../domain/entities/talk.dart';
import 'excel_parser_base.dart';

/// Excel parser service for DDD 2025 conference format.
///
/// Expected columns:
/// 0: ID (skip), 1: Talk Title, 2: Name (skip), 3: Speaker Names (comma-separated),
/// 4: Talk Description, 5: Status (skip), 6: Track (e.g., "Track 7 - Data"),
/// 7: Talk Type (duration), 8: Start Time (filter out "None"), 9: Business Area (venue)
class DddExcelParserService extends ExcelParserBase {
  static const _talkTitleColumn = 1;
  static const _speakerNamesColumn = 3;
  static const _descriptionColumn = 4;
  static const _trackColumn = 6;
  static const _talkTypeColumn = 7;
  static const _startTimeColumn = 8;
  static const _businessAreaColumn = 9;

  @override
  ExcelParseResult parseExcel(Uint8List bytes) {
    final List<Talk> talks = [];
    final List<ParseError> errors = [];
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
          final result = _parseRow(row, rowNumber);
          if (result == null) {
            // Row was skipped (empty or no start time)
            skippedRows++;
          } else {
            talks.add(result);
          }
        } on ParseException catch (e) {
          errors.add(ParseError(rowNumber: rowNumber, reason: e.message));
        }
      }

      return ExcelParseResult(
        talks: talks,
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

  DateTime? _parseDateTime(String dateStr, List<Data?> row, int index) {
    // Check for native DateTimeCellValue first (Excel datetime cells)
    if (index < row.length && row[index] != null) {
      final cell = row[index]!;
      if (cell.value is DateTimeCellValue) {
        final dtValue = cell.value as DateTimeCellValue;
        return DateTime(
          dtValue.year,
          dtValue.month,
          dtValue.day,
          dtValue.hour,
          dtValue.minute,
          dtValue.second,
        );
      }
      if (cell.value is DateCellValue) {
        final dateCellValue = cell.value as DateCellValue;
        return DateTime(
          dateCellValue.year,
          dateCellValue.month,
          dateCellValue.day,
          9, // Default time
          0,
        );
      }
    }

    if (dateStr.isEmpty) return null;

    // Check for "None" or similar values that indicate no scheduled time
    final lowerStr = dateStr.toLowerCase();
    if (lowerStr == 'none' || lowerStr == 'n/a' || lowerStr == 'tba') {
      return null;
    }

    // Try parsing datetime formats
    final datetimeFormats = [
      // yyyy-MM-dd HH:mm:ss
      RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})\s+(\d{1,2}):(\d{2}):(\d{2})$'),
      // yyyy-MM-dd HH:mm
      RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})\s+(\d{1,2}):(\d{2})$'),
      // MM/dd/yyyy HH:mm
      RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})\s+(\d{1,2}):(\d{2})$'),
      // yyyy-MM-dd h:mm a (12-hour with AM/PM)
      RegExp(
        r'^(\d{4})-(\d{1,2})-(\d{1,2})\s+(\d{1,2}):(\d{2})\s*(AM|PM|am|pm)$',
      ),
      // MM/dd/yyyy h:mm a (12-hour with AM/PM)
      RegExp(
        r'^(\d{1,2})/(\d{1,2})/(\d{4})\s+(\d{1,2}):(\d{2})\s*(AM|PM|am|pm)$',
      ),
    ];

    for (final format in datetimeFormats) {
      final match = format.firstMatch(dateStr);
      if (match != null) {
        try {
          final hasSeconds = match.groupCount >= 6 &&
              match.group(6) != null &&
              RegExp(r'^\d+$').hasMatch(match.group(6)!);
          final hasAmPm = match.groupCount >= 6 &&
              match.group(6) != null &&
              RegExp(r'^(AM|PM|am|pm)$').hasMatch(match.group(6)!);

          int hour = int.parse(match.group(4)!);
          final minute = int.parse(match.group(5)!);
          final second = hasSeconds ? int.parse(match.group(6)!) : 0;

          if (hasAmPm) {
            final period = match.group(6)!.toUpperCase();
            if (period == 'PM' && hour != 12) {
              hour += 12;
            } else if (period == 'AM' && hour == 12) {
              hour = 0;
            }
          }

          if (format.pattern.startsWith(r'^(\d{4})')) {
            // yyyy-MM-dd format
            return DateTime(
              int.parse(match.group(1)!),
              int.parse(match.group(2)!),
              int.parse(match.group(3)!),
              hour,
              minute,
              second,
            );
          } else {
            // MM/dd/yyyy format
            return DateTime(
              int.parse(match.group(3)!),
              int.parse(match.group(1)!),
              int.parse(match.group(2)!),
              hour,
              minute,
              second,
            );
          }
        } catch (_) {
          continue;
        }
      }
    }

    // Try DateTime.parse as fallback (handles ISO 8601)
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  /// Extract track number from strings like "Track 7 - Data" -> 7
  int _parseTrack(String trackStr) {
    if (trackStr.isEmpty) return 0;

    // Try to extract number from "Track N - Description" format
    final trackMatch = RegExp(r'Track\s*(\d+)', caseSensitive: false)
        .firstMatch(trackStr);
    if (trackMatch != null) {
      return int.tryParse(trackMatch.group(1)!) ?? 0;
    }

    // Fallback: try to parse as plain number
    return int.tryParse(trackStr) ?? 0;
  }

  /// Parse comma-separated speaker names into Speaker list
  List<Speaker> _parseSpeakers(String speakerNames) {
    if (speakerNames.isEmpty) return [];

    return speakerNames
        .split(',')
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .map((name) => Speaker(name: name, image: ''))
        .toList();
  }

  Talk? _parseRow(List<Data?> row, int rowNumber) {
    // Check if row is empty
    if (row.every(
      (cell) =>
          cell?.value == null || cell?.value.toString().trim().isEmpty == true,
    )) {
      return null;
    }

    // Check Start Time first - skip rows without scheduled time
    final startTimeValue = _getCellValue(row, _startTimeColumn);
    final startTime = _parseDateTime(startTimeValue, row, _startTimeColumn);
    if (startTime == null) {
      // Silently skip rows without a valid start time
      return null;
    }

    final title = _getCellValue(row, _talkTitleColumn);
    if (title.isEmpty) {
      throw const ParseException('Title is required');
    }

    final speakerNames = _getCellValue(row, _speakerNamesColumn);
    final speakers = _parseSpeakers(speakerNames);

    final trackStr = _getCellValue(row, _trackColumn);
    final track = _parseTrack(trackStr);

    return Talk(
      date: startTime,
      title: title,
      description: _getCellValue(row, _descriptionColumn),
      speakers: speakers,
      liveLink: '',
      duration: _getCellValue(row, _talkTypeColumn),
      track: track,
      venue: _getCellValue(row, _businessAreaColumn),
    );
  }
}
