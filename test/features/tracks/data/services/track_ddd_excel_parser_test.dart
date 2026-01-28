import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspire_admin_portal/core/errors/exceptions.dart';
import 'package:inspire_admin_portal/features/tracks/data/services/track_ddd_excel_parser.dart';

void main() {
  late TrackDddExcelParser parserService;

  setUp(() {
    parserService = TrackDddExcelParser();
  });

  Uint8List createExcelBytes({
    List<List<dynamic>>? rows,
    bool includeHeader = true,
  }) {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    // DDD format has many columns, Track is at column 6
    final headerRow = [
      'ID',
      'Talk Title',
      'Name',
      'Speaker Names',
      'Talk Description',
      'Status',
      'Track', // Column 6
      'Talk Type',
      'Start Time',
      'Business Area',
    ];

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

    return Uint8List.fromList(excel.encode()!);
  }

  // Helper to create DDD format rows (track info at column 6)
  List<dynamic> createDddRow(String trackValue) {
    return [
      '1', // ID
      'Talk Title', // Talk Title
      'Name', // Name
      'Speaker', // Speaker Names
      'Description', // Talk Description
      'Accepted', // Status
      trackValue, // Track (column 6)
      '40 min', // Talk Type
      '2024-01-15 10:00', // Start Time
      'Area 1', // Business Area
    ];
  }

  group('TrackDddExcelParser', () {
    group('parseExcel', () {
      test('should parse Track from "Track N - Description" format', () {
        final bytes = createExcelBytes(
          rows: [
            createDddRow('Track 7 - Data & Analytics'),
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.tracks.length, 1);
        expect(result.tracks.first.trackNumber, 7);
        expect(result.tracks.first.trackDescription, 'Data & Analytics');
      });

      test('should extract unique tracks from multiple rows', () {
        final bytes = createExcelBytes(
          rows: [
            createDddRow('Track 1 - Mobile'),
            createDddRow('Track 1 - Mobile'), // Duplicate
            createDddRow('Track 2 - Web'),
            createDddRow('Track 1 - Mobile'), // Duplicate
            createDddRow('Track 3 - Cloud'),
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.tracks.length, 3);
        expect(result.tracks[0].trackNumber, 1);
        expect(result.tracks[1].trackNumber, 2);
        expect(result.tracks[2].trackNumber, 3);
      });

      test('should sort tracks by track number', () {
        final bytes = createExcelBytes(
          rows: [
            createDddRow('Track 5 - Five'),
            createDddRow('Track 2 - Two'),
            createDddRow('Track 8 - Eight'),
            createDddRow('Track 1 - One'),
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.tracks.length, 4);
        expect(result.tracks[0].trackNumber, 1);
        expect(result.tracks[1].trackNumber, 2);
        expect(result.tracks[2].trackNumber, 5);
        expect(result.tracks[3].trackNumber, 8);
      });

      test('should assign colors from palette based on track number', () {
        final bytes = createExcelBytes(
          rows: [
            createDddRow('Track 1 - One'),
            createDddRow('Track 2 - Two'),
            createDddRow('Track 3 - Three'),
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.tracks[0].trackColor, '#2E6CA4'); // palette[0]
        expect(result.tracks[1].trackColor, '#4CAF50'); // palette[1]
        expect(result.tracks[2].trackColor, '#FF9800'); // palette[2]
      });

      test('should handle "Track N" format without description', () {
        final bytes = createExcelBytes(
          rows: [
            createDddRow('Track 4'),
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.tracks.length, 1);
        expect(result.tracks.first.trackNumber, 4);
        expect(result.tracks.first.trackDescription, 'Track 4');
      });

      test('should skip rows with empty track column', () {
        final bytes = createExcelBytes(
          rows: [
            createDddRow('Track 1 - Valid'),
            createDddRow(''),
            createDddRow('Track 2 - Also Valid'),
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.tracks.length, 2);
        expect(result.skippedRows, 1);
      });

      test('should skip completely empty rows', () {
        final bytes = createExcelBytes(
          rows: [
            createDddRow('Track 1 - Valid'),
            [null, null, null, null, null, null, null, null, null, null],
            createDddRow('Track 2 - Also Valid'),
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.tracks.length, 2);
      });

      test('should handle case-insensitive track parsing', () {
        final bytes = createExcelBytes(
          rows: [
            createDddRow('TRACK 1 - Upper'),
            createDddRow('track 2 - lower'),
            createDddRow('Track 3 - Mixed'),
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.tracks.length, 3);
        expect(result.tracks[0].trackNumber, 1);
        expect(result.tracks[1].trackNumber, 2);
        expect(result.tracks[2].trackNumber, 3);
      });

      test('should handle Track N: Description format with colon', () {
        final bytes = createExcelBytes(
          rows: [
            createDddRow('Track 1: With Colon'),
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.tracks.length, 1);
        expect(result.tracks.first.trackNumber, 1);
        expect(result.tracks.first.trackDescription, 'With Colon');
      });

      test('should skip rows that do not match track pattern', () {
        final bytes = createExcelBytes(
          rows: [
            createDddRow('Track 1 - Valid'),
            createDddRow('Not a track'),
            createDddRow('Something else'),
            createDddRow('Track 2 - Also Valid'),
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.tracks.length, 2);
        expect(result.skippedRows, 2);
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

      test('should cycle through color palette for many tracks', () {
        final rows = List.generate(
          12,
          (i) => createDddRow('Track ${i + 1} - Track ${i + 1}'),
        );

        final bytes = createExcelBytes(rows: rows);
        final result = parserService.parseExcel(bytes);

        expect(result.tracks.length, 12);
        // Track 11 -> (11-1) % 10 = 0 -> palette[0] = '#2E6CA4'
        expect(result.tracks[10].trackColor, '#2E6CA4');
        // Track 12 -> (12-1) % 10 = 1 -> palette[1] = '#4CAF50'
        expect(result.tracks[11].trackColor, '#4CAF50');
      });

      test('should trim whitespace from descriptions', () {
        final bytes = createExcelBytes(
          rows: [
            createDddRow('Track 1 -   Lots of Spaces   '),
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.tracks.first.trackDescription, 'Lots of Spaces');
      });

      test('should handle tracks with spaces around number', () {
        final bytes = createExcelBytes(
          rows: [
            createDddRow('Track  5  - Extra Spaces'),
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.tracks.length, 1);
        expect(result.tracks.first.trackNumber, 5);
      });
    });
  });
}
