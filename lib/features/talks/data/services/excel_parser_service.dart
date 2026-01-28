import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/speaker.dart';
import '../../domain/entities/talk.dart';

class ExcelParseResult {
  final List<Talk> talks;
  final List<ParseError> errors;

  const ExcelParseResult({required this.talks, required this.errors});
}

class ExcelParserService {
  static const _dateColumn = 0;
  static const _titleColumn = 1;
  static const _descriptionColumn = 2;
  static const _speakersColumn = 3;
  static const _liveLinkColumn = 4;
  static const _durationColumn = 5;
  static const _trackColumn = 6;
  static const _venueColumn = 7;

  ExcelParseResult parseExcel(Uint8List bytes) {
    final List<Talk> talks = [];
    final List<ParseError> errors = [];

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
          final talk = _parseRow(row, rowNumber);
          if (talk != null) {
            talks.add(talk);
          }
        } on ParseException catch (e) {
          errors.add(ParseError(rowNumber: rowNumber, reason: e.message));
        }
      }

      return ExcelParseResult(talks: talks, errors: errors);
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

  DateTime? _parseDate(String dateStr, List<Data?> row, int index) {
    // Default time for date-only formats (09:00 for backward compatibility)
    const defaultHour = 9;
    const defaultMinute = 0;

    // Check for native DateCellValue first (Excel date cells)
    if (index < row.length && row[index] != null) {
      final cell = row[index]!;
      if (cell.value is DateCellValue) {
        final dateCellValue = cell.value as DateCellValue;
        return DateTime(
          dateCellValue.year,
          dateCellValue.month,
          dateCellValue.day,
          defaultHour,
          defaultMinute,
        );
      }
    }

    if (dateStr.isEmpty) return null;

    // Try parsing datetime formats with time first
    final datetimeFormats = [
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
          final hasAmPm = match.groupCount >= 6 && match.group(6) != null;
          int hour = int.parse(match.group(4)!);
          final minute = int.parse(match.group(5)!);

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
            );
          } else {
            // MM/dd/yyyy format
            return DateTime(
              int.parse(match.group(3)!),
              int.parse(match.group(1)!),
              int.parse(match.group(2)!),
              hour,
              minute,
            );
          }
        } catch (_) {
          continue;
        }
      }
    }

    // Try parsing date-only formats
    final dateOnlyFormats = [
      RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$'), // yyyy-MM-dd
      RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$'), // MM/dd/yyyy
      RegExp(r'^(\d{1,2})-(\d{1,2})-(\d{4})$'), // MM-dd-yyyy
    ];

    for (final format in dateOnlyFormats) {
      final match = format.firstMatch(dateStr);
      if (match != null) {
        try {
          if (format.pattern.startsWith(r'^(\d{4})')) {
            // yyyy-MM-dd format
            return DateTime(
              int.parse(match.group(1)!),
              int.parse(match.group(2)!),
              int.parse(match.group(3)!),
              defaultHour,
              defaultMinute,
            );
          } else {
            // MM/dd/yyyy or MM-dd-yyyy format
            return DateTime(
              int.parse(match.group(3)!),
              int.parse(match.group(1)!),
              int.parse(match.group(2)!),
              defaultHour,
              defaultMinute,
            );
          }
        } catch (_) {
          continue;
        }
      }
    }

    // Try DateTime.parse as fallback (handles ISO 8601)
    try {
      final parsed = DateTime.parse(dateStr);
      // If no time component was in the original string, use default time
      if (!dateStr.contains('T') && !dateStr.contains(':')) {
        return DateTime(
          parsed.year,
          parsed.month,
          parsed.day,
          defaultHour,
          defaultMinute,
        );
      }
      return parsed;
    } catch (_) {
      return null;
    }
  }

  Talk? _parseRow(List<Data?> row, int rowNumber) {
    // Check if row is empty
    if (row.every(
      (cell) =>
          cell?.value == null || cell?.value.toString().trim().isEmpty == true,
    )) {
      return null;
    }

    final title = _getCellValue(row, _titleColumn);
    if (title.isEmpty) {
      throw const ParseException('Title is required');
    }

    final dateValue = _getCellValue(row, _dateColumn);
    final date = _parseDate(dateValue, row, _dateColumn);
    if (date == null) {
      throw const ParseException('Valid date is required');
    }

    final speakersJson = _getCellValue(row, _speakersColumn);
    final speakers = _parseSpeakers(speakersJson);

    return Talk(
      date: date,
      title: title,
      description: _getCellValue(row, _descriptionColumn),
      speakers: speakers,
      liveLink: _getCellValue(row, _liveLinkColumn),
      duration: _getCellValue(row, _durationColumn),
      track: int.tryParse(_getCellValue(row, _trackColumn)) ?? 0,
      venue: _getCellValue(row, _venueColumn),
    );
  }

  List<Speaker> _parseSpeakers(String json) {
    if (json.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(json);
      return decoded
          .map((item) {
            if (item is Map<String, dynamic>) {
              return Speaker(
                name: item['name']?.toString() ?? '',
                image: item['image']?.toString() ?? '',
              );
            }
            return const Speaker(name: '', image: '');
          })
          .where((s) => s.name.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }
}

class ParseError {
  final int rowNumber;
  final String reason;

  const ParseError({required this.rowNumber, required this.reason});
}
