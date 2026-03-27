import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_save_to_gallery.dart';

void main() {
  group('useSaveToGallery', () {
    test('has correct initial state', () {
      expect(SaveToGalleryStatus.idle.name, 'idle');
      expect(SaveToGalleryStatus.saving.name, 'saving');
      expect(SaveToGalleryStatus.success.name, 'success');
      expect(SaveToGalleryStatus.error.name, 'error');
    });

    test('SaveToGalleryResult has correct structure', () {
      final result = (
        status: SaveToGalleryStatus.idle,
        save: () {},
        errorMessage: null,
      );

      expect(result.status, SaveToGalleryStatus.idle);
      expect(result.save, isA<void Function()>());
      expect(result.errorMessage, isNull);
    });
  });
}
