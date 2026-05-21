// Aggregated entrypoint so the iOS suite builds once, not once per file.
import 'basic_messaging_flow_test.dart' as basic_messaging_flow;
import 'messaging_interactions_test.dart' as messaging_interactions;

void main() {
  basic_messaging_flow.main();
  messaging_interactions.main();
}
