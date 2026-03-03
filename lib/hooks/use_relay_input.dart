import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/utils/relay_url_validation.dart';
import 'package:whitenoise/widgets/wn_icon.dart' show WnIcons;

final _logger = Logger('useRelayInput');

String _validationErrorToKey(RelayValidationError error) {
  return switch (error) {
    RelayValidationError.invalidScheme => 'invalidRelayUrlScheme',
    RelayValidationError.invalidUrl => 'invalidRelayUrl',
  };
}

typedef RelayInputResult = ({
  TextEditingController controller,
  bool isValid,
  String? validationError,
  void Function() handleTrailingAction,
  WnIcons trailingIcon,
  String trailingKey,
});

RelayInputResult useRelayInput() {
  final controller = useTextEditingController(text: 'wss://');
  final isValid = useState(false);
  final validationError = useState<String?>(null);
  final debounceTimer = useRef<Timer?>(null);
  final hasText = useState(false);
  final context = useContext();

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
      validationError.value = _validationErrorToKey(error);
    }
  }

  void updateHasText() {
    hasText.value = !isRelayUrlEmpty(controller.text);
  }

  void onUrlChanged() {
    debounceTimer.value?.cancel();
    isValid.value = false;
    updateHasText();
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
    if (!context.mounted) return;
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (!context.mounted) return;
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

  void clear() {
    controller.text = 'wss://';
    isValid.value = false;
    validationError.value = null;
    hasText.value = false;
    debounceTimer.value?.cancel();
  }

  void handleTrailingAction() {
    if (hasText.value) {
      clear();
    } else {
      paste();
    }
  }

  final trailingIcon = hasText.value ? WnIcons.closeSmall : WnIcons.paste;
  final trailingKey = hasText.value ? 'clear_button' : 'paste_button';

  return (
    controller: controller,
    isValid: isValid.value,
    validationError: validationError.value,
    handleTrailingAction: handleTrailingAction,
    trailingIcon: trailingIcon,
    trailingKey: trailingKey,
  );
}
