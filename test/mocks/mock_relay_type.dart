import 'package:rust_lib_whitenoise/src/rust/api/accounts.dart';

class MockRelayType implements RelayType {
  final String type;
  MockRelayType(this.type);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
