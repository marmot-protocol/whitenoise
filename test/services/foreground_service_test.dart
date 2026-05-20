import 'dart:async' show Completer;
import 'dart:ui' show Locale;

import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/services/foreground_service.dart';

class _MockForegroundTaskApi extends ForegroundTaskApi {
  final List<String> calls = [];
  final List<Object> sentData = [];
  ForegroundTaskOptions? capturedTaskOptions;
  bool isRunning = false;
  bool isIgnoringBattery = false;
  ServiceRequestResult startResult = const ServiceRequestSuccess();
  ServiceRequestResult stopResult = const ServiceRequestSuccess();
  List<ForegroundServiceTypes>? lastServiceTypes;

  @override
  void initCommunicationPort() => calls.add('initCommunicationPort');

  NotificationIcon? lastNotificationIcon;

  @override
  void init({
    required AndroidNotificationOptions androidNotificationOptions,
    required IOSNotificationOptions iosNotificationOptions,
    required ForegroundTaskOptions foregroundTaskOptions,
  }) {
    calls.add('init');
    capturedTaskOptions = foregroundTaskOptions;
  }

  @override
  Future<bool> get isRunningService async => isRunning;

  @override
  Future<ServiceRequestResult> startService({
    required int serviceId,
    List<ForegroundServiceTypes>? serviceTypes,
    required String notificationTitle,
    required String notificationText,
    NotificationIcon? notificationIcon,
    required Function callback,
  }) async {
    calls.add('startService');
    if (startResult is ServiceRequestSuccess) {
      isRunning = true;
      lastServiceTypes = serviceTypes;
      lastNotificationIcon = notificationIcon;
    }
    return startResult;
  }

  @override
  Future<ServiceRequestResult> stopService() async {
    calls.add('stopService');
    if (stopResult is ServiceRequestSuccess) {
      isRunning = false;
    }
    return stopResult;
  }

  @override
  Future<bool> get isIgnoringBatteryOptimizations async => isIgnoringBattery;

  @override
  Future<bool> requestIgnoreBatteryOptimization() async {
    calls.add('requestIgnoreBatteryOptimization');
    return true;
  }

  @override
  void sendDataToTask(Object data) {
    calls.add('sendDataToTask');
    sentData.add(data);
  }
}

Future<void> _flushTaskHandler() => Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationTaskHandler', () {
    test('repeat retries bootstrap and subscription after boot startup failure', () async {
      var bootstrapCalls = 0;
      var loadLocaleCalls = 0;
      var ensureSubscriptionsCalls = 0;
      var startSubscriptionCalls = 0;

      final handler = NotificationTaskHandler(
        bootstrapIsolate: () async => ++bootstrapCalls > 1,
        loadLocale: () async {
          loadLocaleCalls++;
          return const Locale('en');
        },
        ensureExternalSigners: () async {},
        ensureSubscriptions: () async {
          ensureSubscriptionsCalls++;
        },
        startSubscription: () async {
          startSubscriptionCalls++;
          return true;
        },
      );

      await handler.onStart(DateTime(2026), TaskStarter.system);

      expect(bootstrapCalls, 1);
      expect(loadLocaleCalls, 0);
      expect(startSubscriptionCalls, 0);

      handler.onRepeatEvent(DateTime(2026));
      await _flushTaskHandler();

      expect(bootstrapCalls, 2);
      expect(loadLocaleCalls, 1);
      expect(ensureSubscriptionsCalls, 1);
      expect(startSubscriptionCalls, 1);
    });

    test('repeat leaves subscription stopped when bootstrap retry still fails', () async {
      var bootstrapCalls = 0;
      var startSubscriptionCalls = 0;

      final handler = NotificationTaskHandler(
        bootstrapIsolate: () async {
          bootstrapCalls++;
          return false;
        },
        startSubscription: () async {
          startSubscriptionCalls++;
          return true;
        },
      );

      await handler.onStart(DateTime(2026), TaskStarter.system);
      handler.onRepeatEvent(DateTime(2026));
      await _flushTaskHandler();

      expect(bootstrapCalls, 2);
      expect(startSubscriptionCalls, 0);
    });

    test('repeat health-checks relay subscriptions without duplicating stream', () async {
      var bootstrapCalls = 0;
      var ensureSubscriptionsCalls = 0;
      var startSubscriptionCalls = 0;
      var subscriptionRunning = false;

      final handler = NotificationTaskHandler(
        bootstrapIsolate: () async {
          bootstrapCalls++;
          return true;
        },
        loadLocale: () async => const Locale('en'),
        ensureExternalSigners: () async {},
        ensureSubscriptions: () async {
          ensureSubscriptionsCalls++;
        },
        startSubscription: () async {
          startSubscriptionCalls++;
          subscriptionRunning = true;
          return true;
        },
        isSubscriptionRunning: () => subscriptionRunning,
      );

      await handler.onStart(DateTime(2026), TaskStarter.system);
      handler.onRepeatEvent(DateTime(2026));
      await _flushTaskHandler();

      expect(bootstrapCalls, 1);
      expect(ensureSubscriptionsCalls, 2);
      expect(startSubscriptionCalls, 1);
    });

    test('system-started task registers external signers before subscribing', () async {
      final calls = <String>[];

      final handler = NotificationTaskHandler(
        bootstrapIsolate: () async => true,
        loadLocale: () async => const Locale('en'),
        ensureExternalSigners: () async {
          calls.add('externalSigners');
        },
        ensureSubscriptions: () async {
          calls.add('relaySubscriptions');
        },
        startSubscription: () async {
          calls.add('notificationStream');
          return true;
        },
      );

      await handler.onStart(DateTime(2026), TaskStarter.system);

      expect(calls, [
        'externalSigners',
        'relaySubscriptions',
        'notificationStream',
      ]);
    });

    test('developer-started task waits for main_stopped before subscribing', () async {
      var ensureSubscriptionsCalls = 0;
      var startSubscriptionCalls = 0;

      final handler = NotificationTaskHandler(
        bootstrapIsolate: () async => true,
        loadLocale: () async => const Locale('en'),
        ensureExternalSigners: () async {},
        ensureSubscriptions: () async {
          ensureSubscriptionsCalls++;
        },
        startSubscription: () async {
          startSubscriptionCalls++;
          return true;
        },
      );

      await handler.onStart(DateTime(2026), TaskStarter.developer);
      handler.onRepeatEvent(DateTime(2026));
      await _flushTaskHandler();

      expect(ensureSubscriptionsCalls, 0);
      expect(startSubscriptionCalls, 0);

      handler.onReceiveData({'event': 'main_stopped'});
      await _flushTaskHandler();

      expect(ensureSubscriptionsCalls, 1);
      expect(startSubscriptionCalls, 1);
    });

    test('does not start notification stream when relay subscription health check fails', () async {
      var startSubscriptionCalls = 0;

      final handler = NotificationTaskHandler(
        bootstrapIsolate: () async => true,
        loadLocale: () async => const Locale('en'),
        ensureExternalSigners: () async {},
        ensureSubscriptions: () async {
          throw Exception('relay subscription failure');
        },
        startSubscription: () async {
          startSubscriptionCalls++;
          return true;
        },
      );

      await handler.onStart(DateTime(2026), TaskStarter.system);

      expect(startSubscriptionCalls, 0);
    });

    test('does not start relay or notification streams when signer registration fails', () async {
      var ensureSubscriptionsCalls = 0;
      var startSubscriptionCalls = 0;

      final handler = NotificationTaskHandler(
        bootstrapIsolate: () async => true,
        loadLocale: () async => const Locale('en'),
        ensureExternalSigners: () async {
          throw Exception('required signer unavailable');
        },
        ensureSubscriptions: () async {
          ensureSubscriptionsCalls++;
        },
        startSubscription: () async {
          startSubscriptionCalls++;
          return true;
        },
      );

      await handler.onStart(DateTime(2026), TaskStarter.system);

      expect(ensureSubscriptionsCalls, 0);
      expect(startSubscriptionCalls, 0);
    });

    test('does not subscribe after ownership is yielded during startup', () async {
      final signerCompleter = Completer<void>();
      var ensureSubscriptionsCalls = 0;
      var startSubscriptionCalls = 0;

      final handler = NotificationTaskHandler(
        bootstrapIsolate: () async => true,
        loadLocale: () async => const Locale('en'),
        ensureExternalSigners: () => signerCompleter.future,
        ensureSubscriptions: () async {
          ensureSubscriptionsCalls++;
        },
        startSubscription: () async {
          startSubscriptionCalls++;
          return true;
        },
      );

      final startFuture = handler.onStart(DateTime(2026), TaskStarter.system);
      await _flushTaskHandler();

      handler.onReceiveData({'event': 'main_started'});
      signerCompleter.complete();
      await startFuture;
      await _flushTaskHandler();

      expect(ensureSubscriptionsCalls, 0);
      expect(startSubscriptionCalls, 0);
    });

    test('destroy stops the owned subscription', () async {
      final calls = <String>[];
      var subscriptionRunning = false;

      final handler = NotificationTaskHandler(
        bootstrapIsolate: () async => true,
        loadLocale: () async => const Locale('en'),
        ensureExternalSigners: () async {},
        ensureSubscriptions: () async {},
        startSubscription: () async {
          calls.add('start');
          subscriptionRunning = true;
          return true;
        },
        isSubscriptionRunning: () => subscriptionRunning,
        stopSubscription: () async {
          calls.add('stop');
          subscriptionRunning = false;
        },
      );

      await handler.onStart(DateTime(2026), TaskStarter.system);
      await handler.onDestroy(DateTime(2026), false);

      expect(calls, ['start', 'stop']);
    });

    test('button and dismissal callbacks are no-ops', () {
      final handler = NotificationTaskHandler();

      handler.onNotificationButtonPressed('ignored');
      handler.onNotificationDismissed();
    });
  });

  group('PendingNotificationTap', () {
    test('uses payload fields for equality and hash code', () {
      const tap = PendingNotificationTap(
        groupId: 'group-1',
        isInvite: false,
        receiverPubkey: 'receiver-1',
      );
      const matching = PendingNotificationTap(
        groupId: 'group-1',
        isInvite: false,
        receiverPubkey: 'receiver-1',
      );
      const different = PendingNotificationTap(
        groupId: 'group-2',
        isInvite: false,
        receiverPubkey: 'receiver-1',
      );

      expect(tap, matching);
      expect(tap.hashCode, matching.hashCode);
      expect(tap, isNot(different));
    });
  });

  group('ForegroundService', () {
    group('when disabled', () {
      late ForegroundService service;

      setUp(() {
        service = ForegroundService(enabled: false);
      });

      test('initialize is no-op', () async {
        await service.initialize();
      });

      test('start is no-op', () async {
        await service.start();
      });

      test('stop is no-op', () async {
        await service.stop();
      });

      test('isRunning returns false', () async {
        expect(await service.isRunning, isFalse);
      });

      test('requestBatteryOptimizationExemption is no-op', () async {
        await service.requestBatteryOptimizationExemption();
      });
    });

    group('when enabled', () {
      late _MockForegroundTaskApi mockApi;
      late ForegroundService service;

      setUp(() {
        mockApi = _MockForegroundTaskApi();
        service = ForegroundService(
          enabled: true,
          api: mockApi,
          packageName: 'org.parres.whitenoise',
        );
      });

      group('initialize', () {
        test('calls initCommunicationPort and init', () async {
          await service.initialize();

          expect(mockApi.calls, ['initCommunicationPort', 'init']);
        });

        test('enables autoRunOnBoot and autoRunOnMyPackageReplaced', () async {
          await service.initialize();

          expect(mockApi.capturedTaskOptions?.autoRunOnBoot, isTrue);
          expect(mockApi.capturedTaskOptions?.autoRunOnMyPackageReplaced, isTrue);
        });

        test('second call is no-op', () async {
          await service.initialize();
          mockApi.calls.clear();

          await service.initialize();

          expect(mockApi.calls, isEmpty);
        });
      });

      group('start', () {
        test('initializes first when not initialized', () async {
          await service.start();

          expect(mockApi.calls, ['initCommunicationPort', 'init', 'startService']);
        });

        test('skips initialize when already initialized', () async {
          await service.initialize();
          mockApi.calls.clear();

          await service.start();

          expect(mockApi.calls, ['startService']);
        });

        test('does not restart an already running service', () async {
          await service.initialize();
          mockApi.calls.clear();
          mockApi.isRunning = true;

          await service.start();

          expect(mockApi.calls, isEmpty);
        });

        test('does not restart after starting with current options', () async {
          await service.start();
          mockApi.calls.clear();

          await service.start();

          expect(mockApi.calls, isEmpty);
        });

        test('passes notification icon from metadata', () async {
          await service.start();
          expect(
            mockApi.lastNotificationIcon?.metaDataName,
            'org.parres.whitenoise.NOTIFICATION_ICON',
          );
        });

        test('passes dataSync foreground service type', () async {
          await service.start();

          expect(mockApi.lastServiceTypes, const [ForegroundServiceTypes.dataSync]);
        });

        test('handles start failure', () async {
          mockApi.startResult = const ServiceRequestFailure(error: 'test error');

          await service.start();

          expect(mockApi.calls, contains('startService'));
          expect(mockApi.isRunning, isFalse);
          expect(mockApi.lastServiceTypes, isNull);
          expect(mockApi.lastNotificationIcon, isNull);
        });
      });

      group('stop', () {
        test('calls stopService', () async {
          await service.stop();

          expect(mockApi.calls, ['stopService']);
        });

        test('handles stop failure', () async {
          mockApi.isRunning = true;
          mockApi.stopResult = const ServiceRequestFailure(error: 'test error');

          await service.stop();

          expect(mockApi.calls, ['stopService']);
          expect(mockApi.isRunning, isTrue);
        });
      });

      test('isRunning delegates to api', () async {
        mockApi.isRunning = true;

        expect(await service.isRunning, isTrue);
      });

      group('requestBatteryOptimizationExemption', () {
        test('requests when not ignoring', () async {
          await service.requestBatteryOptimizationExemption();

          expect(mockApi.calls, ['requestIgnoreBatteryOptimization']);
        });

        test('skips when already ignoring', () async {
          mockApi.isIgnoringBattery = true;

          await service.requestBatteryOptimizationExemption();

          expect(mockApi.calls, isEmpty);
        });
      });

      group('notifyMainStarted / notifyMainStopped', () {
        test('notifyMainStarted sends event when service is running', () async {
          mockApi.isRunning = true;

          await service.notifyMainStarted();

          expect(mockApi.calls, contains('sendDataToTask'));
          expect(mockApi.sentData, [
            {'event': 'main_started'},
          ]);
        });

        test('notifyMainStarted is a no-op when service is not running', () async {
          mockApi.isRunning = false;

          await service.notifyMainStarted();

          expect(mockApi.calls, isNot(contains('sendDataToTask')));
        });

        test('notifyMainStopped sends event when service is running', () async {
          mockApi.isRunning = true;

          await service.notifyMainStopped();

          expect(mockApi.calls, contains('sendDataToTask'));
          expect(mockApi.sentData, [
            {'event': 'main_stopped'},
          ]);
        });

        test('notifyMainStopped is a no-op when service is not running', () async {
          mockApi.isRunning = false;

          await service.notifyMainStopped();

          expect(mockApi.calls, isNot(contains('sendDataToTask')));
        });
      });
    });

    group('when disabled (coordination)', () {
      late ForegroundService service;

      setUp(() {
        service = ForegroundService(enabled: false);
      });

      test('notifyMainStarted is no-op', () async {
        await service.notifyMainStarted();
      });

      test('notifyMainStopped is no-op', () async {
        await service.notifyMainStopped();
      });

      test('handleAppLifecycleChange is no-op for all states', () async {
        await service.handleAppLifecycleChange(AppLifecycleState.resumed);
        await service.handleAppLifecycleChange(AppLifecycleState.paused);
        await service.handleAppLifecycleChange(AppLifecycleState.inactive);
        await service.handleAppLifecycleChange(AppLifecycleState.hidden);
        await service.handleAppLifecycleChange(AppLifecycleState.detached);
      });
    });

    group('handleAppLifecycleChange', () {
      late _MockForegroundTaskApi mockApi;
      late ForegroundService service;

      setUp(() {
        mockApi = _MockForegroundTaskApi();
        mockApi.isRunning = true;
        service = ForegroundService(
          enabled: true,
          api: mockApi,
          packageName: 'org.parres.whitenoise',
        );
      });

      test('resumed sends main_started', () async {
        await service.handleAppLifecycleChange(AppLifecycleState.resumed);

        expect(mockApi.sentData, [
          {'event': 'main_started'},
        ]);
      });

      test('paused sends main_stopped', () async {
        await service.handleAppLifecycleChange(AppLifecycleState.paused);

        expect(mockApi.sentData, [
          {'event': 'main_stopped'},
        ]);
      });

      test('inactive sends main_stopped', () async {
        await service.handleAppLifecycleChange(AppLifecycleState.inactive);

        expect(mockApi.sentData, [
          {'event': 'main_stopped'},
        ]);
      });

      test('hidden sends main_stopped', () async {
        await service.handleAppLifecycleChange(AppLifecycleState.hidden);

        expect(mockApi.sentData, [
          {'event': 'main_stopped'},
        ]);
      });

      test('detached sends main_stopped', () async {
        await service.handleAppLifecycleChange(AppLifecycleState.detached);

        expect(mockApi.sentData, [
          {'event': 'main_stopped'},
        ]);
      });
    });
  });
}
