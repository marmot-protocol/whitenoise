import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/utils/relay_url_validation.dart';

final _logger = Logger('useAddRelay');

({
  TextEditingController controller,
  bool isValid,
  String? validationError,
  void Function() paste,
})
useAddRelay() {
  final controller = useTextEditingController(text: 'wss://');
  final isValid = useState(false);
  final validationError = useState<String?>(null);
  final debounceTimer = useRef<Timer?>(null);

  void runValidation() {
    final url = controller.text.trim();

    if (isRelayUrlEmpty(url)) {
      isValid.value = false;
      validationError.value = null;
      return;
    }

    final error = validateRelayUrl(url);

    if (error == null) {
      isValid.value = true;
      validationError.value = null;
    } else {
      isValid.value = false;
      validationError.value = error;
    }
  }

  void onUrlChanged() {
    debounceTimer.value?.cancel();
    isValid.value = false;
    debounceTimer.value = Timer(const Duration(milliseconds: 500), runValidation);
  }

  useEffect(() {
    controller.addListener(onUrlChanged);
    return () {
      debounceTimer.value?.cancel();
      controller.removeListener(onUrlChanged);
    };
  }, [controller]);

  Future<void> paste() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null) {
        final String pastedText = clipboardData!.text!.trim();

        if (pastedText.startsWith('wss://') || pastedText.startsWith('ws://')) {
          controller.text = pastedText;
        } else {
          controller.text = 'wss://$pastedText';
        }

        debounceTimer.value?.cancel();
        debounceTimer.value = Timer(const Duration(milliseconds: 100), runValidation);
      }
    } catch (e) {
      _logger.warning('Failed to paste from clipboard: $e');
    }
  }

  return (
    controller: controller,
    isValid: isValid.value,
    validationError: validationError.value,
    paste: paste,
  );
}
