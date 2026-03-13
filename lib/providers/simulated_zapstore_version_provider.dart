import 'package:flutter_riverpod/flutter_riverpod.dart';

class SimulatedZapstoreVersionNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setVersion(String? version) {
    state = version;
  }
}

final simulatedZapstoreVersionProvider =
    NotifierProvider<SimulatedZapstoreVersionNotifier, String?>(
      SimulatedZapstoreVersionNotifier.new,
    );
