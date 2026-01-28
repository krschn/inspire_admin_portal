import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspire_admin_portal/core/errors/exceptions.dart';
import 'package:inspire_admin_portal/features/talks/data/services/excel_parser_service.dart';

void main() {
  late StandardExcelParserService parserService;

  setUp(() {
    parserService = StandardExcelParserService();
  });

  Uint8List createExcelBytes({
    List<List<dynamic>>? rows,
    bool includeHeader = true,
  }) {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    final headerRow = [
      'Date',
      'Title',
      'Description',
      'Speakers',
      'Live Link',
      'Duration',
      'Track',
      'Venue',
    ];

    if (includeHeader) {
      for (int i = 0; i < headerRow.length; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .value = TextCellValue(
          headerRow[i],
        );
      }
    }

    if (rows != null) {
      final startRow = includeHeader ? 1 : 0;
      for (int rowIndex = 0; rowIndex < rows.length; rowIndex++) {
        final row = rows[rowIndex];
        for (int colIndex = 0; colIndex < row.length; colIndex++) {
          final value = row[colIndex];
          if (value != null) {
            if (value is DateTime) {
              sheet
                  .cell(
                    CellIndex.indexByColumnRow(
                      columnIndex: colIndex,
                      rowIndex: startRow + rowIndex,
                    ),
                  )
                  .value = DateCellValue(
                year: value.year,
                month: value.month,
                day: value.day,
              );
            } else {
              sheet
                  .cell(
                    CellIndex.indexByColumnRow(
                      columnIndex: colIndex,
                      rowIndex: startRow + rowIndex,
                    ),
                  )
                  .value = TextCellValue(
                value.toString(),
              );
            }
          }
        }
      }
    }

    // Remove default Sheet1 if we created our own
    if (excel.tables.containsKey('Sheet1') && excel.tables.length > 1) {
      excel.delete('Sheet1');
    }

    return Uint8List.fromList(excel.encode()!);
  }

  String createSpeakersJson(List<Map<String, String>> speakers) {
    return jsonEncode(speakers);
  }

  group('StandardExcelParserService', () {
    group('parseExcel', () {
      test('should parse valid Excel with all fields', () {
        final speakersJson = createSpeakersJson([
          {'name': 'John Doe', 'image': 'https://example.com/john.jpg'},
        ]);

        final bytes = createExcelBytes(
          rows: [
            [
              '2024-01-15',
              'Test Talk',
              'Test Description',
              speakersJson,
              'https://example.com/live',
              '30 min',
              '1',
              'Room 101',
            ],
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.talks.length, 1);
        expect(result.errors, isEmpty);
        expect(result.talks.first.title, 'Test Talk');
        expect(result.talks.first.description, 'Test Description');
        expect(result.talks.first.date.year, 2024);
        expect(result.talks.first.date.month, 1);
        expect(result.talks.first.date.day, 15);
        expect(result.talks.first.speakers.length, 1);
        expect(result.talks.first.speakers.first.name, 'John Doe');
        expect(result.talks.first.liveLink, 'https://example.com/live');
        expect(result.talks.first.duration, '30 min');
        expect(result.talks.first.track, 1);
        expect(result.talks.first.venue, 'Room 101');
      });

      test('should parse multiple rows', () {
        final bytes = createExcelBytes(
          rows: [
            [
              '2024-01-15',
              'Talk 1',
              'Desc 1',
              '[]',
              '',
              '30 min',
              'Track A',
              'Room 1',
            ],
            [
              '2024-01-16',
              'Talk 2',
              'Desc 2',
              '[]',
              '',
              '45 min',
              'Track B',
              'Room 2',
            ],
            [
              '2024-01-17',
              'Talk 3',
              'Desc 3',
              '[]',
              '',
              '60 min',
              'Track C',
              'Room 3',
            ],
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.talks.length, 3);
        expect(result.errors, isEmpty);
        expect(result.talks[0].title, 'Talk 1');
        expect(result.talks[1].title, 'Talk 2');
        expect(result.talks[2].title, 'Talk 3');
      });

      test('should parse date in yyyy-MM-dd format with default time 09:00', () {
        final bytes = createExcelBytes(
          rows: [
            ['2024-01-15', 'Talk', 'Desc', '[]', '', '', '', ''],
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.talks.first.date.year, 2024);
        expect(result.talks.first.date.month, 1);
        expect(result.talks.first.date.day, 15);
        expect(result.talks.first.date.hour, 9);
        expect(result.talks.first.date.minute, 0);
      });

      test('should parse date in MM/dd/yyyy format with default time 09:00', () {
        final bytes = createExcelBytes(
          rows: [
            ['01/15/2024', 'Talk', 'Desc', '[]', '', '', '', ''],
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.talks.first.date.year, 2024);
        expect(result.talks.first.date.month, 1);
        expect(result.talks.first.date.day, 15);
        expect(result.talks.first.date.hour, 9);
        expect(result.talks.first.date.minute, 0);
      });

      test('should parse date in MM-dd-yyyy format with default time 09:00', () {
        final bytes = createExcelBytes(
          rows: [
            ['01-15-2024', 'Talk', 'Desc', '[]', '', '', '', ''],
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.talks.first.date.year, 2024);
        expect(result.talks.first.date.month, 1);
        expect(result.talks.first.date.day, 15);
        expect(result.talks.first.date.hour, 9);
        expect(result.talks.first.date.minute, 0);
      });

      test('should parse DateCellValue from Excel with default time 09:00', () {
        final bytes = createExcelBytes(
          rows: [
            [DateTime(2024, 1, 15), 'Talk', 'Desc', '[]', '', '', '', ''],
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.talks.first.date.year, 2024);
        expect(result.talks.first.date.month, 1);
        expect(result.talks.first.date.day, 15);
        expect(result.talks.first.date.hour, 9);
        expect(result.talks.first.date.minute, 0);
      });

      test('should parse datetime in yyyy-MM-dd HH:mm format', () {
        final bytes = createExcelBytes(
          rows: [
            ['2024-01-15 17:30', 'Talk', 'Desc', '[]', '', '', '', ''],
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.talks.first.date.year, 2024);
        expect(result.talks.first.date.month, 1);
        expect(result.talks.first.date.day, 15);
        expect(result.talks.first.date.hour, 17);
        expect(result.talks.first.date.minute, 30);
      });

      test('should parse datetime in MM/dd/yyyy HH:mm format', () {
        final bytes = createExcelBytes(
          rows: [
            ['01/15/2024 14:00', 'Talk', 'Desc', '[]', '', '', '', ''],
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.talks.first.date.year, 2024);
        expect(result.talks.first.date.month, 1);
        expect(result.talks.first.date.day, 15);
        expect(result.talks.first.date.hour, 14);
        expect(result.talks.first.date.minute, 0);
      });

      test('should parse datetime in yyyy-MM-dd h:mm AM format', () {
        final bytes = createExcelBytes(
          rows: [
            ['2024-01-15 9:30 AM', 'Talk', 'Desc', '[]', '', '', '', ''],
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.talks.first.date.year, 2024);
        expect(result.talks.first.date.month, 1);
        expect(result.talks.first.date.day, 15);
        expect(result.talks.first.date.hour, 9);
        expect(result.talks.first.date.minute, 30);
      });

      test('should parse datetime in yyyy-MM-dd h:mm PM format', () {
        final bytes = createExcelBytes(
          rows: [
            ['2024-01-15 5:30 PM', 'Talk', 'Desc', '[]', '', '', '', ''],
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.talks.first.date.year, 2024);
        expect(result.talks.first.date.month, 1);
        expect(result.talks.first.date.day, 15);
        expect(result.talks.first.date.hour, 17);
        expect(result.talks.first.date.minute, 30);
      });

      test('should parse datetime 12:00 PM as noon', () {
        final bytes = createExcelBytes(
          rows: [
            ['2024-01-15 12:00 PM', 'Talk', 'Desc', '[]', '', '', '', ''],
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.talks.first.date.hour, 12);
        expect(result.talks.first.date.minute, 0);
      });

      test('should parse datetime 12:00 AM as midnight', () {
        final bytes = createExcelBytes(
          rows: [
            ['2024-01-15 12:00 AM', 'Talk', 'Desc', '[]', '', '', '', ''],
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.talks.first.date.hour, 0);
        expect(result.talks.first.date.minute, 0);
      });

      test('should parse ISO 8601 datetime format', () {
        final bytes = createExcelBytes(
          rows: [
            ['2024-01-15T17:30:00', 'Talk', 'Desc', '[]', '', '', '', ''],
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.talks.first.date.year, 2024);
        expect(result.talks.first.date.month, 1);
        expect(result.talks.first.date.day, 15);
        expect(result.talks.first.date.hour, 17);
        expect(result.talks.first.date.minute, 30);
      });

      test('should add error when title is missing', () {
        final bytes = createExcelBytes(
          rows: [
            ['2024-01-15', '', 'Desc', '[]', '', '', '', ''],
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.talks, isEmpty);
        expect(result.errors.length, 1);
        expect(result.errors.first.rowNumber, 2);
        expect(result.errors.first.reason, 'Title is required');
      });

      test('should add error when date is missing', () {
        final bytes = createExcelBytes(
          rows: [
            ['', 'Talk Title', 'Desc', '[]', '', '', '', ''],
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.talks, isEmpty);
        expect(result.errors.length, 1);
        expect(result.errors.first.rowNumber, 2);
        expect(result.errors.first.reason, 'Valid date is required');
      });

      test('should add error when date is invalid', () {
        final bytes = createExcelBytes(
          rows: [
            ['invalid-date', 'Talk Title', 'Desc', '[]', '', '', '', ''],
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.talks, isEmpty);
        expect(result.errors.length, 1);
        expect(result.errors.first.reason, 'Valid date is required');
      });

      test('should skip empty rows', () {
        final bytes = createExcelBytes(
          rows: [
            ['2024-01-15', 'Talk 1', 'Desc 1', '[]', '', '', '', ''],
            [null, null, null, null, null, null, null, null],
            ['2024-01-16', 'Talk 2', 'Desc 2', '[]', '', '', '', ''],
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.talks.length, 2);
        expect(result.errors, isEmpty);
      });

      test('should parse speakers JSON correctly', () {
        final speakersJson = createSpeakersJson([
          {'name': 'Speaker 1', 'image': 'https://example.com/1.jpg'},
          {'name': 'Speaker 2', 'image': 'https://example.com/2.jpg'},
        ]);

        final bytes = createExcelBytes(
          rows: [
            ['2024-01-15', 'Talk', 'Desc', speakersJson, '', '', '', ''],
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.talks.first.speakers.length, 2);
        expect(result.talks.first.speakers[0].name, 'Speaker 1');
        expect(result.talks.first.speakers[1].name, 'Speaker 2');
      });

      test('should return empty speakers list for invalid JSON', () {
        final bytes = createExcelBytes(
          rows: [
            ['2024-01-15', 'Talk', 'Desc', 'invalid json', '', '', '', ''],
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.talks.first.speakers, isEmpty);
      });

      test('should return empty speakers list for empty string', () {
        final bytes = createExcelBytes(
          rows: [
            ['2024-01-15', 'Talk', 'Desc', '', '', '', '', ''],
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.talks.first.speakers, isEmpty);
      });

      test('should filter out speakers with empty names', () {
        final speakersJson = jsonEncode([
          {'name': 'Valid Speaker', 'image': 'https://example.com/valid.jpg'},
          {'name': '', 'image': 'https://example.com/empty.jpg'},
        ]);

        final bytes = createExcelBytes(
          rows: [
            ['2024-01-15', 'Talk', 'Desc', speakersJson, '', '', '', ''],
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.talks.first.speakers.length, 1);
        expect(result.talks.first.speakers.first.name, 'Valid Speaker');
      });

      test('should throw ParseException for empty Excel file', () {
        final excel = Excel.createExcel();
        final bytes = Uint8List.fromList(excel.encode()!);

        expect(
          () => parserService.parseExcel(bytes),
          throwsA(isA<ParseException>()),
        );
      });

      test('should throw ParseException for Excel with only header row', () {
        final bytes = createExcelBytes(rows: []);

        expect(
          () => parserService.parseExcel(bytes),
          throwsA(
            isA<ParseException>().having(
              (e) => e.message,
              'message',
              'Excel file must have a header row and at least one data row',
            ),
          ),
        );
      });

      test('should handle missing optional columns gracefully', () {
        final bytes = createExcelBytes(
          rows: [
            ['2024-01-15', 'Talk', '', '', '', '', '', ''],
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.talks.length, 1);
        expect(result.talks.first.title, 'Talk');
        expect(result.talks.first.description, '');
        expect(result.talks.first.speakers, isEmpty);
        expect(result.talks.first.liveLink, '');
        expect(result.talks.first.duration, '');
        expect(result.talks.first.track, 0);
        expect(result.talks.first.venue, '');
      });

      test('should collect errors for multiple invalid rows', () {
        final bytes = createExcelBytes(
          rows: [
            ['', 'Talk 1', 'Desc', '[]', '', '', '', ''], // Missing date
            ['2024-01-15', '', 'Desc', '[]', '', '', '', ''], // Missing title
            ['2024-01-16', 'Valid Talk', 'Desc', '[]', '', '', '', ''], // Valid
            ['invalid', 'Talk 3', 'Desc', '[]', '', '', '', ''], // Invalid date
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.talks.length, 1);
        expect(result.talks.first.title, 'Valid Talk');
        expect(result.errors.length, 3);
        expect(result.errors[0].rowNumber, 2);
        expect(result.errors[1].rowNumber, 3);
        expect(result.errors[2].rowNumber, 5);
      });
    });
  });
}
