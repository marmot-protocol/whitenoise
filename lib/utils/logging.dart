import 'package:logging/logging.dart';

void logDuration(Logger logger, String message, int milliseconds) {
  if (milliseconds >= 50) {
    logger.warning('$message ${milliseconds}ms');
  } else {
    logger.info('$message ${milliseconds}ms');
  }
}
