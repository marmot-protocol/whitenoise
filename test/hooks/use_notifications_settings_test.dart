import 'dart:async' show Completer, unawaited;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_notifications_settings.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

class _BlockableMockApi extends MockWnApi {
  Completer<AccountSettings>? updateCompleter;

  @override
  Future<AccountSettings> crateApiAccountsUpdateNotificationsEnabled({
    required String pubkey,
    required bool enabled,
  }) async {
    if (updateCompleter != null) {
      return updateCompleter!.future;
    }
    return super.crateApiAccountsUpdateNotificationsEnabled(pubkey: pubkey, enabled: enabled);
  }
}

void main() {
  late _BlockableMockApi mockApi;

  setUpAll(() {
    mockApi = _BlockableMockApi();
    RustLib.initMock(api: mockApi);
  });

  setUp(() {
    mockApi.reset();
    mockApi.updateCompleter = null;
  });

  Future<
    ({
      AsyncSnapshot<AccountSettings?> settings,
      bool isUpdating,
      String? error,
      Future<void> Function(bool) updateNotifications,
      void Function() clearError,
    })
    Function()
  >
  mountHookWidget(WidgetTester tester, {String pubkey = testPubkeyA}) {
    return mountHook(
      tester,
      () => useNotificationsSettings(pubkey),
    );
  }

  testWidgets('loads account settings on init with notificationsEnabled: true', (tester) async {
    mockApi.mockNotificationsEnabled = true;
    final getResult = await mountHookWidget(tester);

    await tester.pump();

    final result = getResult();
    expect(result.settings.connectionState, ConnectionState.done);
    expect(result.settings.data?.notificationsEnabled, true);
    expect(result.isUpdating, false);
  });

  testWidgets('loads account settings with notificationsEnabled: false', (tester) async {
    mockApi.mockNotificationsEnabled = false;
    final getResult = await mountHookWidget(tester);

    await tester.pump();

    final result = getResult();
    expect(result.settings.connectionState, ConnectionState.done);
    expect(result.settings.data?.notificationsEnabled, false);
  });

  testWidgets('returns error state when accountSettings API throws', (tester) async {
    mockApi.shouldFailAccountSettings = true;
    final getResult = await mountHookWidget(tester);

    await tester.pump();

    final result = getResult();
    expect(result.settings.hasError, true);
  });

  testWidgets('sets error to settingsLoadFailed code when accountSettings throws', (tester) async {
    mockApi.shouldFailAccountSettings = true;
    final getResult = await mountHookWidget(tester);

    await tester.pump();

    expect(getResult().error, settingsLoadFailed);
  });

  testWidgets('sets error to settingsUpdateFailed code when update throws', (tester) async {
    mockApi.shouldFailUpdateNotificationsEnabled = true;
    final getResult = await mountHookWidget(tester);
    await tester.pump();

    await tester.runAsync(() => getResult().updateNotifications(false));
    await tester.pump();

    expect(getResult().error, settingsUpdateFailed);
  });

  testWidgets('clearError resets error to null', (tester) async {
    mockApi.shouldFailUpdateNotificationsEnabled = true;
    final getResult = await mountHookWidget(tester);
    await tester.pump();

    await tester.runAsync(() => getResult().updateNotifications(false));
    await tester.pump();
    getResult().clearError();
    await tester.pump();

    expect(getResult().error, null);
  });

  testWidgets('updateNotifications calls updateNotificationsEnabled with correct args', (
    tester,
  ) async {
    mockApi.mockNotificationsEnabled = true;
    final getResult = await mountHookWidget(tester);
    await tester.pump();

    final update = getResult().updateNotifications;
    await tester.runAsync(() => update(false));
    await tester.pump();

    expect(mockApi.mockNotificationsEnabled, false);
  });

  testWidgets('isUpdating is true during update call and false after', (tester) async {
    mockApi.mockNotificationsEnabled = true;
    final updateCompleter = Completer<AccountSettings>();
    mockApi.updateCompleter = updateCompleter;

    final getResult = await mountHookWidget(tester);
    await tester.pump();

    unawaited(getResult().updateNotifications(false));
    await tester.pump();

    expect(getResult().isUpdating, true);

    updateCompleter.complete(const AccountSettings(notificationsEnabled: false));
    await tester.pumpAndSettle();

    expect(getResult().isUpdating, false);
  });

  testWidgets('after updateNotifications(false), returned settings reflect new value', (
    tester,
  ) async {
    mockApi.mockNotificationsEnabled = true;
    final getResult = await mountHookWidget(tester);
    await tester.pump();

    await tester.runAsync(() => getResult().updateNotifications(false));
    await tester.pump();

    expect(getResult().settings.data?.notificationsEnabled, false);
  });

  testWidgets('after updateNotifications(true), returned settings reflect new value', (
    tester,
  ) async {
    mockApi.mockNotificationsEnabled = false;
    final getResult = await mountHookWidget(tester);
    await tester.pump();

    await tester.runAsync(() => getResult().updateNotifications(true));
    await tester.pump();

    expect(getResult().settings.data?.notificationsEnabled, true);
  });
}
