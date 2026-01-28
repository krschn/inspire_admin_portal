import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspire_admin_portal/core/errors/exceptions.dart';
import 'package:inspire_admin_portal/features/tracks/data/services/track_standard_excel_parser.dart';

void main() {
  late TrackStandardExcelParser parserService;

  setUp(() {
    parserService = TrackStandardExcelParser();
  });

  Uint8List createExcelBytes({
    List<List<dynamic>>? rows,
    bool includeHeader = true,
  }) {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    final headerRow = ['track_number', 'track_description', 'track_color'];

    if (includeHeader) {
      for (int i = 0; i < headerRow.length; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .value = TextCellValue(headerRow[i]);
      }
    }

    if (rows != null) {
      final startRow = includeHeader ? 1 : 0;
      for (int rowIndex = 0; rowIndex < rows.length; rowIndex++) {
        final row = rows[rowIndex];
        for (int colIndex = 0; colIndex < row.length; colIndex++) {
          final value = row[colIndex];
          if (value != null) {
            if (value is int) {
              sheet
                  .cell(
                    CellIndex.indexByColumnRow(
                      columnIndex: colIndex,
                      rowIndex: startRow + rowIndex,
                    ),
                  )
                  .value = IntCellValue(value);
            } else {
              sheet
                  .cell(
                    CellIndex.indexByColumnRow(
                      columnIndex: colIndex,
                      rowIndex: startRow + rowIndex,
                    ),
                  )
                  .value = TextCellValue(value.toString());
            }
          }
        }
      }
    }

    return Uint8List.fromList(excel.encode()!);
  }

  group('TrackStandardExcelParser', () {
    group('parseExcel', () {
      test('should parse valid Excel with all fields', () {
        final bytes = createExcelBytes(
          rows: [
            [1, 'Data & Analytics', '#2E6CA4'],
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.tracks.length, 1);
        expect(result.errors, isEmpty);
        expect(result.tracks.first.trackNumber, 1);
        expect(result.tracks.first.trackDescription, 'Data & Analytics');
        expect(result.tracks.first.trackColor, '#2E6CA4');
      });

      test('should parse multiple rows', () {
        final bytes = createExcelBytes(
          rows: [
            [1, 'Track One', '#2E6CA4'],
            [2, 'Track Two', '#4CAF50'],
            [3, 'Track Three', '#FF9800'],
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.tracks.length, 3);
        expect(result.errors, isEmpty);
        expect(result.tracks[0].trackNumber, 1);
        expect(result.tracks[1].trackNumber, 2);
        expect(result.tracks[2].trackNumber, 3);
      });

      test('should assign default color from palette when color is empty', () {
        final bytes = createExcelBytes(
          rows: [
            [1, 'Track One', ''],
            [2, 'Track Two', ''],
            [3, 'Track Three', ''],
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.tracks.length, 3);
        // Colors should be assigned based on track number
        expect(result.tracks[0].trackColor, '#2E6CA4'); // Track 1 -> palette[0]
        expect(result.tracks[1].trackColor, '#4CAF50'); // Track 2 -> palette[1]
        expect(result.tracks[2].trackColor, '#FF9800'); // Track 3 -> palette[2]
      });

      test('should assign color from palette based on track number', () {
        final bytes = createExcelBytes(
          rows: [
            [5, 'Track Five', ''],
            [7, 'Track Seven', ''],
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.tracks.length, 2);
        // Track 5 -> (5-1) % 10 = 4 -> palette[4] = '#E91E63'
        expect(result.tracks[0].trackColor, '#E91E63');
        // Track 7 -> (7-1) % 10 = 6 -> palette[6] = '#795548'
        expect(result.tracks[1].trackColor, '#795548');
      });

      test('should use provided color when valid', () {
        final bytes = createExcelBytes(
          rows: [
            [1, 'Track One', '#123456'],
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.tracks.first.trackColor, '#123456');
      });

      test('should add error when color format is invalid', () {
        final bytes = createExcelBytes(
          rows: [
            [1, 'Track One', 'invalid-color'],
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.tracks, isEmpty);
        expect(result.errors.length, 1);
        expect(result.errors.first.reason, contains('Invalid color format'));
      });

      test('should add error when track number is missing', () {
        final bytes = createExcelBytes(
          rows: [
            ['', 'Track Description', '#2E6CA4'],
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.tracks, isEmpty);
        expect(result.errors.length, 1);
        expect(result.errors.first.rowNumber, 2);
        expect(result.errors.first.reason, contains('Track number is required'));
      });

      test('should add error when description is missing', () {
        final bytes = createExcelBytes(
          rows: [
            [1, '', '#2E6CA4'],
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.tracks, isEmpty);
        expect(result.errors.length, 1);
        expect(result.errors.first.rowNumber, 2);
        expect(result.errors.first.reason, contains('Track description is required'));
      });

      test('should skip empty rows', () {
        final bytes = createExcelBytes(
          rows: [
            [1, 'Track 1', '#2E6CA4'],
            [null, null, null],
            [2, 'Track 2', '#4CAF50'],
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.tracks.length, 2);
        expect(result.errors, isEmpty);
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

      test('should collect errors for multiple invalid rows', () {
        final bytes = createExcelBytes(
          rows: [
            ['', 'Track 1', '#2E6CA4'], // Missing track number
            [2, '', '#4CAF50'], // Missing description
            [3, 'Valid Track', '#FF9800'], // Valid
            [4, 'Track 4', 'bad-color'], // Invalid color
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.tracks.length, 1);
        expect(result.tracks.first.trackDescription, 'Valid Track');
        expect(result.errors.length, 3);
        expect(result.errors[0].rowNumber, 2);
        expect(result.errors[1].rowNumber, 3);
        expect(result.errors[2].rowNumber, 5);
      });

      test('should parse track number as string', () {
        final bytes = createExcelBytes(
          rows: [
            ['5', 'Track Five', '#2E6CA4'],
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.tracks.length, 1);
        expect(result.tracks.first.trackNumber, 5);
      });

      test('should handle double values for track number', () {
        final excel = Excel.createExcel();
        final sheet = excel['Sheet1'];

        // Header
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =
            TextCellValue('track_number');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value =
            TextCellValue('track_description');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0)).value =
            TextCellValue('track_color');

        // Data row with double
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value =
            DoubleCellValue(3.0);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1)).value =
            TextCellValue('Track Three');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 1)).value =
            TextCellValue('#2E6CA4');

        final bytes = Uint8List.fromList(excel.encode()!);
        final result = parserService.parseExcel(bytes);

        expect(result.tracks.length, 1);
        expect(result.tracks.first.trackNumber, 3);
      });

      test('should validate hex color format strictly', () {
        final validColors = ['#2E6CA4', '#FFFFFF', '#000000', '#abcdef', '#AbCdEf'];
        final invalidColors = ['#2E6CA', '#2E6CA44', '2E6CA4', '#GGGGGG', 'red'];

        for (final color in validColors) {
          final bytes = createExcelBytes(
            rows: [[1, 'Track', color]],
          );
          final result = parserService.parseExcel(bytes);
          expect(result.tracks.length, 1, reason: '$color should be valid');
        }

        for (final color in invalidColors) {
          final bytes = createExcelBytes(
            rows: [[1, 'Track', color]],
          );
          final result = parserService.parseExcel(bytes);
          expect(result.errors.length, 1, reason: '$color should be invalid');
        }
      });
    });
  });
}
