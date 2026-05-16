import Flutter
import UIKit
import UserNotifications

@_silgen_name("wn_install_ios_background_keyring_store_with_access_group")
private func wn_install_ios_background_keyring_store_with_access_group(
  _ accessGroupPtr: UnsafePointer<UInt8>?,
  _ accessGroupLen: Int
) -> Bool

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let pushChannelName = "org.parres.whitenoise/push_notifications"
  private let appGroupChannelName = "org.parres.whitenoise/app_group"
  private var pushChannel: FlutterMethodChannel?
  private var appGroupChannel: FlutterMethodChannel?
  private var latestApnsToken: String?
  private var pendingNotificationTap: [String: Any]?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let didFinish = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    installBackgroundKeyringStore()
    if let registrar = registrar(forPlugin: "WhitenoisePushNotificationsPlugin") {
      configurePushChannel(binaryMessenger: registrar.messenger())
      configureAppGroupChannel(binaryMessenger: registrar.messenger())
    } else if let controller = window?.rootViewController as? FlutterViewController {
      configurePushChannel(binaryMessenger: controller.binaryMessenger)
      configureAppGroupChannel(binaryMessenger: controller.binaryMessenger)
    } else {
      NSLog("White Noise push MethodChannel could not be configured")
    }
    UNUserNotificationCenter.current().delegate = self
    application.registerForRemoteNotifications()
    return didFinish
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    let token = deviceToken.map { String(format: "%02x", $0) }.joined()
    latestApnsToken = token
    pushChannel?.invokeMethod("providerPushTokenUpdated", arguments: providerPushTokenMap(token))
    NSLog("White Noise APNS token available: %d bytes", deviceToken.count)
#if DEBUG
    NSLog("APNs registration succeeded with token: %@", token)
#endif
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    NSLog("White Noise APNS registration failed: %@", error.localizedDescription)
#if DEBUG
    NSLog("APNs registration failed: %@", error.localizedDescription)
#endif
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func configurePushChannel(binaryMessenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: pushChannelName, binaryMessenger: binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(nil)
        return
      }
      switch call.method {
      case "getProviderPushToken":
        if let latestApnsToken {
          result(providerPushTokenMap(latestApnsToken))
        } else {
          result(nil)
        }
      case "requestNotificationPermission":
        requestNotificationPermission(result)
      case "consumePendingNotificationTap":
        result(consumePendingNotificationTap())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    pushChannel = channel
    NSLog("White Noise push MethodChannel configured")
  }

  private func configureAppGroupChannel(binaryMessenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: appGroupChannelName, binaryMessenger: binaryMessenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "getAppGroupContainerPath":
        result(self.appGroupContainerPath())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    appGroupChannel = channel
    NSLog("White Noise App Group MethodChannel configured")
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    if storePendingNotificationTap(from: response.notification.request.content.userInfo) {
      completionHandler()
      return
    }

    super.userNotificationCenter(
      center,
      didReceive: response,
      withCompletionHandler: completionHandler
    )
  }

  private func consumePendingNotificationTap() -> [String: Any]? {
    let tap = pendingNotificationTap
    pendingNotificationTap = nil
    return tap
  }

  private func storePendingNotificationTap(from userInfo: [AnyHashable: Any]) -> Bool {
    guard let tap = notificationTapPayload(from: userInfo) else {
      return false
    }
    pendingNotificationTap = tap
    NSLog("White Noise stored pending APNS notification tap")
    return true
  }

  private func notificationTapPayload(from userInfo: [AnyHashable: Any]) -> [String: Any]? {
    let groupId = stringValue(userInfo["groupId"])
      ?? stringValue(userInfo["mlsGroupId"])
      ?? stringValue(userInfo["mls_group_id"])
    let receiverPubkey = stringValue(userInfo["receiverPubkey"])
      ?? stringValue(userInfo["receiver_pubkey"])
    let trigger = stringValue(userInfo["trigger"])
    let isInvite = boolValue(userInfo["isInvite"])
      ?? trigger.map(isInviteTrigger)
      ?? false

    guard
      let groupId,
      !groupId.isEmpty,
      let receiverPubkey,
      !receiverPubkey.isEmpty
    else {
      return nil
    }

    return [
      "groupId": groupId,
      "isInvite": isInvite,
      "receiverPubkey": receiverPubkey,
    ]
  }

  private func stringValue(_ value: Any?) -> String? {
    guard let string = value as? String else {
      return nil
    }
    let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }

  private func boolValue(_ value: Any?) -> Bool? {
    if let bool = value as? Bool {
      return bool
    }
    if let number = value as? NSNumber {
      return number.boolValue
    }
    if let string = stringValue(value) {
      if string == "true" || string == "1" {
        return true
      }
      if string == "false" || string == "0" {
        return false
      }
    }
    return nil
  }

  private func isInviteTrigger(_ trigger: String) -> Bool {
    trigger == "invite" || trigger == "group_invite" || trigger == "GroupInvite"
  }

  private func appGroupContainerPath() -> String? {
    guard
      let identifier = Bundle.main.object(forInfoDictionaryKey: "WNAppGroupIdentifier") as? String,
      !identifier.isEmpty,
      let url = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: identifier
      )
    else {
      return nil
    }
    return url.path
  }

  private func providerPushTokenMap(_ token: String) -> [String: String] {
    [
      "platform": "apns",
      "rawToken": token,
    ]
  }

  private func requestNotificationPermission(_ result: @escaping FlutterResult) {
    let center = UNUserNotificationCenter.current()
    center.getNotificationSettings { settings in
      switch settings.authorizationStatus {
      case .authorized, .provisional, .ephemeral:
        DispatchQueue.main.async {
          result(true)
        }
      case .denied:
        DispatchQueue.main.async {
          result(false)
        }
      case .notDetermined:
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
          DispatchQueue.main.async {
            result(granted)
          }
        }
      @unknown default:
        DispatchQueue.main.async {
          result(false)
        }
      }
    }
  }

  private func installBackgroundKeyringStore() {
    let installed = withUtf8Buffer(keychainAccessGroup() ?? "") { accessGroupPtr, accessGroupLen in
      wn_install_ios_background_keyring_store_with_access_group(accessGroupPtr, accessGroupLen)
    }
    guard installed else {
      NSLog("White Noise failed to install iOS background keyring store")
      return
    }
  }

  private func keychainAccessGroup() -> String? {
    Bundle.main.object(forInfoDictionaryKey: "WNKeychainAccessGroup") as? String
  }

  private func withUtf8Buffer<T>(
    _ string: String,
    _ body: (UnsafePointer<UInt8>?, Int) -> T
  ) -> T {
    let bytes = Array(string.utf8)
    return bytes.withUnsafeBufferPointer { buffer in
      body(buffer.baseAddress, buffer.count)
    }
  }
}
