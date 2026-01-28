import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inspire_admin_portal/core/errors/exceptions.dart';
import 'package:inspire_admin_portal/features/talks/data/services/ddd_excel_parser_service.dart';

void main() {
  late DddExcelParserService parserService;

  setUp(() {
    parserService = DddExcelParserService();
  });

  Uint8List createDddExcelBytes({
    List<List<dynamic>>? rows,
    bool includeHeader = true,
  }) {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    // DDD 2025 format headers
    final headerRow = [
      'ID',
      'Talk Title',
      'Name',
      'Speaker Names',
      'Talk Description',
      'Status',
      'Track',
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
            if (value is DateTime) {
              sheet
                  .cell(
                    CellIndex.indexByColumnRow(
                      columnIndex: colIndex,
                      rowIndex: startRow + rowIndex,
                    ),
                  )
                  .value = DateTimeCellValue(
                year: value.year,
                month: value.month,
                day: value.day,
                hour: value.hour,
                minute: value.minute,
                second: value.second,
              );
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

    // Remove default Sheet1 if we created our own
    if (excel.tables.containsKey('Sheet1') && excel.tables.length > 1) {
      excel.delete('Sheet1');
    }

    return Uint8List.fromList(excel.encode()!);
  }

  /// Create a valid DDD row with all fields
  List<dynamic> createValidDddRow({
    String id = '1',
    String title = 'Test Talk',
    String name = 'John',
    String speakerNames = 'John Doe',
    String description = 'Test Description',
    String status = 'Confirmed',
    String track = 'Track 1 - General',
    String talkType = '45 min',
    dynamic startTime = '2024-01-15 10:00',
    String businessArea = 'Room 101',
  }) {
    return [
      id,
      title,
      name,
      speakerNames,
      description,
      status,
      track,
      talkType,
      startTime,
      businessArea,
    ];
  }

  group('DddExcelParserService', () {
    group('parseExcel', () {
      test('should parse valid DDD format with all fields', () {
        final bytes = createDddExcelBytes(
          rows: [
            createValidDddRow(
              id: '42',
              title: 'Building Microservices',
              speakerNames: 'John Doe',
              description: 'Learn about microservices architecture',
              track: 'Track 7 - Data',
              talkType: '45 min',
              startTime: '2024-03-15 14:30',
              businessArea: 'Main Hall',
            ),
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.talks.length, 1);
        expect(result.errors, isEmpty);

        final talk = result.talks.first;
        expect(talk.title, 'Building Microservices');
        expect(talk.description, 'Learn about microservices architecture');
        expect(talk.date.year, 2024);
        expect(talk.date.month, 3);
        expect(talk.date.day, 15);
        expect(talk.date.hour, 14);
        expect(talk.date.minute, 30);
        expect(talk.speakers.length, 1);
        expect(talk.speakers.first.name, 'John Doe');
        expect(talk.duration, '45 min');
        expect(talk.track, 7);
        expect(talk.venue, 'Main Hall');
        expect(talk.liveLink, '');
      });

      test('should parse multiple rows', () {
        final bytes = createDddExcelBytes(
          rows: [
            createValidDddRow(title: 'Talk 1', startTime: '2024-01-15 09:00'),
            createValidDddRow(title: 'Talk 2', startTime: '2024-01-15 10:00'),
            createValidDddRow(title: 'Talk 3', startTime: '2024-01-15 11:00'),
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.talks.length, 3);
        expect(result.errors, isEmpty);
        expect(result.talks[0].title, 'Talk 1');
        expect(result.talks[1].title, 'Talk 2');
        expect(result.talks[2].title, 'Talk 3');
      });

      test('should filter out rows with empty Start Time', () {
        final bytes = createDddExcelBytes(
          rows: [
            createValidDddRow(title: 'Scheduled Talk', startTime: '2024-01-15 10:00'),
            createValidDddRow(title: 'Unscheduled Talk', startTime: ''),
            createValidDddRow(title: 'Another Scheduled', startTime: '2024-01-15 11:00'),
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.talks.length, 2);
        expect(result.skippedRows, 1);
        expect(result.errors, isEmpty);
        expect(result.talks[0].title, 'Scheduled Talk');
        expect(result.talks[1].title, 'Another Scheduled');
      });

      test('should filter out rows with "None" Start Time', () {
        final bytes = createDddExcelBytes(
          rows: [
            createValidDddRow(title: 'Scheduled Talk', startTime: '2024-01-15 10:00'),
            createValidDddRow(title: 'Virtual Stage Talk', startTime: 'None'),
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.talks.length, 1);
        expect(result.skippedRows, 1);
        expect(result.talks.first.title, 'Scheduled Talk');
      });

      test('should filter out rows with "N/A" or "TBA" Start Time', () {
        final bytes = createDddExcelBytes(
          rows: [
            createValidDddRow(title: 'Valid Talk', startTime: '2024-01-15 10:00'),
            createValidDddRow(title: 'N/A Talk', startTime: 'N/A'),
            createValidDddRow(title: 'TBA Talk', startTime: 'TBA'),
          ],
        );

        final result = parserService.parseExcel(bytes);

        expect(result.talks.length, 1);
        expect(result.skippedRows, 2);
      });

      group('track number extraction', () {
        test('should extract track number from "Track 7 - Data"', () {
          final bytes = createDddExcelBytes(
            rows: [
              createValidDddRow(track: 'Track 7 - Data'),
            ],
          );

          final result = parserService.parseExcel(bytes);
          expect(result.talks.first.track, 7);
        });

        test('should extract track number from "Track 1 - General"', () {
          final bytes = createDddExcelBytes(
            rows: [
              createValidDddRow(track: 'Track 1 - General'),
            ],
          );

          final result = parserService.parseExcel(bytes);
          expect(result.talks.first.track, 1);
        });

        test('should extract track number from "Track12" (no space)', () {
          final bytes = createDddExcelBytes(
            rows: [
              createValidDddRow(track: 'Track12'),
            ],
          );

          final result = parserService.parseExcel(bytes);
          expect(result.talks.first.track, 12);
        });

        test('should return 0 for empty track', () {
          final bytes = createDddExcelBytes(
            rows: [
              createValidDddRow(track: ''),
            ],
          );

          final result = parserService.parseExcel(bytes);
          expect(result.talks.first.track, 0);
        });

        test('should return 0 for track without number', () {
          final bytes = createDddExcelBytes(
            rows: [
              createValidDddRow(track: 'Main Stage'),
            ],
          );

          final result = parserService.parseExcel(bytes);
          expect(result.talks.first.track, 0);
        });

        test('should parse plain number as track', () {
          final bytes = createDddExcelBytes(
            rows: [
              createValidDddRow(track: '5'),
            ],
          );

          final result = parserService.parseExcel(bytes);
          expect(result.talks.first.track, 5);
        });
      });

      group('comma-separated speakers', () {
        test('should parse single speaker', () {
          final bytes = createDddExcelBytes(
            rows: [
              createValidDddRow(speakerNames: 'John Doe'),
            ],
          );

          final result = parserService.parseExcel(bytes);
          expect(result.talks.first.speakers.length, 1);
          expect(result.talks.first.speakers.first.name, 'John Doe');
        });

        test('should parse multiple comma-separated speakers', () {
          final bytes = createDddExcelBytes(
            rows: [
              createValidDddRow(speakerNames: 'John Doe, Jane Smith, Bob Wilson'),
            ],
          );

          final result = parserService.parseExcel(bytes);
          expect(result.talks.first.speakers.length, 3);
          expect(result.talks.first.speakers[0].name, 'John Doe');
          expect(result.talks.first.speakers[1].name, 'Jane Smith');
          expect(result.talks.first.speakers[2].name, 'Bob Wilson');
        });

        test('should trim whitespace from speaker names', () {
          final bytes = createDddExcelBytes(
            rows: [
              createValidDddRow(speakerNames: '  John Doe  ,  Jane Smith  '),
            ],
          );

          final result = parserService.parseExcel(bytes);
          expect(result.talks.first.speakers.length, 2);
          expect(result.talks.first.speakers[0].name, 'John Doe');
          expect(result.talks.first.speakers[1].name, 'Jane Smith');
        });

        test('should filter out empty speaker names', () {
          final bytes = createDddExcelBytes(
            rows: [
              createValidDddRow(speakerNames: 'John Doe, , Jane Smith'),
            ],
          );

          final result = parserService.parseExcel(bytes);
          expect(result.talks.first.speakers.length, 2);
          expect(result.talks.first.speakers[0].name, 'John Doe');
          expect(result.talks.first.speakers[1].name, 'Jane Smith');
        });

        test('should return empty list for empty speaker names', () {
          final bytes = createDddExcelBytes(
            rows: [
              createValidDddRow(speakerNames: ''),
            ],
          );

          final result = parserService.parseExcel(bytes);
          expect(result.talks.first.speakers, isEmpty);
        });

        test('should set empty image for all speakers', () {
          final bytes = createDddExcelBytes(
            rows: [
              createValidDddRow(speakerNames: 'John Doe, Jane Smith'),
            ],
          );

          final result = parserService.parseExcel(bytes);
          expect(result.talks.first.speakers[0].image, '');
          expect(result.talks.first.speakers[1].image, '');
        });
      });

      group('Business Area to venue mapping', () {
        test('should map Business Area to venue field', () {
          final bytes = createDddExcelBytes(
            rows: [
              createValidDddRow(businessArea: 'Main Hall'),
            ],
          );

          final result = parserService.parseExcel(bytes);
          expect(result.talks.first.venue, 'Main Hall');
        });

        test('should handle empty Business Area', () {
          final bytes = createDddExcelBytes(
            rows: [
              createValidDddRow(businessArea: ''),
            ],
          );

          final result = parserService.parseExcel(bytes);
          expect(result.talks.first.venue, '');
        });
      });

      group('datetime parsing', () {
        test('should parse yyyy-MM-dd HH:mm format', () {
          final bytes = createDddExcelBytes(
            rows: [
              createValidDddRow(startTime: '2024-03-15 14:30'),
            ],
          );

          final result = parserService.parseExcel(bytes);
          final date = result.talks.first.date;
          expect(date.year, 2024);
          expect(date.month, 3);
          expect(date.day, 15);
          expect(date.hour, 14);
          expect(date.minute, 30);
        });

        test('should parse yyyy-MM-dd HH:mm:ss format', () {
          final bytes = createDddExcelBytes(
            rows: [
              createValidDddRow(startTime: '2024-03-15 14:30:45'),
            ],
          );

          final result = parserService.parseExcel(bytes);
          final date = result.talks.first.date;
          expect(date.year, 2024);
          expect(date.month, 3);
          expect(date.day, 15);
          expect(date.hour, 14);
          expect(date.minute, 30);
          expect(date.second, 45);
        });

        test('should parse DateTimeCellValue from Excel', () {
          final bytes = createDddExcelBytes(
            rows: [
              createValidDddRow(startTime: DateTime(2024, 3, 15, 14, 30, 0)),
            ],
          );

          final result = parserService.parseExcel(bytes);
          final date = result.talks.first.date;
          expect(date.year, 2024);
          expect(date.month, 3);
          expect(date.day, 15);
          expect(date.hour, 14);
          expect(date.minute, 30);
        });

        test('should parse ISO 8601 format', () {
          final bytes = createDddExcelBytes(
            rows: [
              createValidDddRow(startTime: '2024-03-15T14:30:00'),
            ],
          );

          final result = parserService.parseExcel(bytes);
          final date = result.talks.first.date;
          expect(date.year, 2024);
          expect(date.month, 3);
          expect(date.day, 15);
          expect(date.hour, 14);
          expect(date.minute, 30);
        });
      });

      group('error handling', () {
        test('should add error when title is missing', () {
          final bytes = createDddExcelBytes(
            rows: [
              createValidDddRow(title: ''),
            ],
          );

          final result = parserService.parseExcel(bytes);

          expect(result.talks, isEmpty);
          expect(result.errors.length, 1);
          expect(result.errors.first.rowNumber, 2);
          expect(result.errors.first.reason, 'Title is required');
        });

        test('should skip empty rows', () {
          final bytes = createDddExcelBytes(
            rows: [
              createValidDddRow(title: 'Valid Talk'),
              [null, null, null, null, null, null, null, null, null, null],
              createValidDddRow(title: 'Another Valid Talk'),
            ],
          );

          final result = parserService.parseExcel(bytes);

          expect(result.talks.length, 2);
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
          final bytes = createDddExcelBytes(rows: []);

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
      });

      group('Talk Type to duration mapping', () {
        test('should map Talk Type to duration field', () {
          final bytes = createDddExcelBytes(
            rows: [
              createValidDddRow(talkType: '45 min'),
            ],
          );

          final result = parserService.parseExcel(bytes);
          expect(result.talks.first.duration, '45 min');
        });

        test('should handle Keynote as duration', () {
          final bytes = createDddExcelBytes(
            rows: [
              createValidDddRow(talkType: 'Keynote'),
            ],
          );

          final result = parserService.parseExcel(bytes);
          expect(result.talks.first.duration, 'Keynote');
        });

        test('should handle 10 min lightning talks', () {
          final bytes = createDddExcelBytes(
            rows: [
              createValidDddRow(talkType: '10 min'),
            ],
          );

          final result = parserService.parseExcel(bytes);
          expect(result.talks.first.duration, '10 min');
        });
      });
    });
  });
}
