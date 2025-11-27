import 'package:logging/logging.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

/// Utility class for camera-related operations.
class CameraUtils {
  CameraUtils._();
  static final Logger logger = Logger('CameraUtils');

  /// Safely starts the camera with permission checks and error handling.
  ///
  /// This method checks camera permissions before attempting to start the camera.
  /// If permissions are denied or permanently denied, it returns without starting.
  /// Any errors during camera startup are logged.
  ///
  /// Parameters:
  /// - [controller]: The MobileScannerController to start
  static Future<void> safeStartCamera(MobileScannerController controller) async {
    try {
      final status = await Permission.camera.status;
      if (status.isDenied || status.isPermanentlyDenied) {
        return;
      }
      await controller.start();
    } catch (e, s) {
      logger.warning('Failed to start camera', e, s);
    }
  }
}
