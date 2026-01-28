import 'dart:typed_data';

import '../../domain/entities/talk.dart';

/// Enum representing available Excel format types
enum ExcelFormat {
  standard('Standard Format', 'Default format with standard expected columns'),
  ddd2025('DDD 2025 Format', 'DDD 2025 conference format');

  final String displayName;
  final String description;

  const ExcelFormat(this.displayName, this.description);
}

/// Base class for Excel parsers
abstract class ExcelParserBase {
  /// Parse an Excel file from bytes and return the result
  ExcelParseResult parseExcel(Uint8List bytes);
}

/// Result of parsing an Excel file
class ExcelParseResult {
  final List<Talk> talks;
  final List<ParseError> errors;
  final int skippedRows;

  const ExcelParseResult({
    required this.talks,
    required this.errors,
    this.skippedRows = 0,
  });
}

/// Represents an error that occurred while parsing a specific row
class ParseError {
  final int rowNumber;
  final String reason;

  const ParseError({required this.rowNumber, required this.reason});
}
