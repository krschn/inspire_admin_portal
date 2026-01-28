import 'dart:typed_data';

import '../../domain/entities/track.dart';

/// Enum representing available Excel format types for tracks
enum TrackExcelFormat {
  standard('Standard Format', 'Default format with track_number, track_description, track_color columns'),
  ddd2025('DDD 2025 Format', 'Extract unique tracks from DDD 2025 talks Excel');

  final String displayName;
  final String description;

  const TrackExcelFormat(this.displayName, this.description);
}

/// Base class for Track Excel parsers
abstract class TrackExcelParserBase {
  /// Parse an Excel file from bytes and return the result
  TrackExcelParseResult parseExcel(Uint8List bytes);
}

/// Result of parsing an Excel file for tracks
class TrackExcelParseResult {
  final List<Track> tracks;
  final List<TrackParseError> errors;
  final int skippedRows;

  const TrackExcelParseResult({
    required this.tracks,
    required this.errors,
    this.skippedRows = 0,
  });
}

/// Represents an error that occurred while parsing a specific row
class TrackParseError {
  final int rowNumber;
  final String reason;

  const TrackParseError({required this.rowNumber, required this.reason});
}
