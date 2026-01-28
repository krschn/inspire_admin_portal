import 'ddd_excel_parser_service.dart';
import 'excel_parser_base.dart';
import 'excel_parser_service.dart';

/// Factory for creating Excel parser instances based on format type
class ExcelParserFactory {
  /// Get a parser instance for the specified format
  static ExcelParserBase getParser(ExcelFormat format) {
    switch (format) {
      case ExcelFormat.standard:
        return StandardExcelParserService();
      case ExcelFormat.ddd2025:
        return DddExcelParserService();
    }
  }

  /// Get all available Excel formats
  static List<ExcelFormat> get availableFormats => ExcelFormat.values;
}
