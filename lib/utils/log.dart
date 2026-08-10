import 'package:logger/logger.dart';

var _logger = Logger(printer: PrettyPrinter());

void logPrint(String message) {
  _logger.d(message);
}

void logWarn(String message) {
  _logger.w(message);
}

void logError(String message) {
  _logger.e(message);
}
