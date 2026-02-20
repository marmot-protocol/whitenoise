import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:whitenoise/widgets/wn_dropdown_selector.dart';

WnDropdownController useDropdownController() {
  final controller = useMemoized(() => WnDropdownController(), const []);

  useEffect(() {
    return controller.dispose;
  }, [controller]);

  return controller;
}
