import 'track_ddd_excel_parser.dart';
import 'track_excel_parser_base.dart';
import 'track_standard_excel_parser.dart';

/// Factory for creating Track Excel parser instances based on format type
class TrackExcelParserFactory {
  /// Get a parser instance for the specified format
  static TrackExcelParserBase getParser(TrackExcelFormat format) {
    switch (format) {
      case TrackExcelFormat.standard:
        return TrackStandardExcelParser();
      case TrackExcelFormat.ddd2025:
        return TrackDddExcelParser();
    }
  }

  /// Get all available Excel formats for tracks
  static List<TrackExcelFormat> get availableFormats => TrackExcelFormat.values;
}
