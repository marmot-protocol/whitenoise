import Foundation
import UserNotifications

private typealias WnJsonCallback = @convention(c) (
  UnsafePointer<UInt8>?,
  Int,
  UnsafeMutableRawPointer?
) -> Void

@_silgen_name("wn_collect_notifications_after_push")
private func wn_collect_notifications_after_push(
  _ dataDirPtr: UnsafePointer<UInt8>?,
  _ dataDirLen: Int,
  _ logsDirPtr: UnsafePointer<UInt8>?,
  _ logsDirLen: Int,
  _ keyringServiceIdPtr: UnsafePointer<UInt8>?,
  _ keyringServiceIdLen: Int,
  _ maxWaitMs: UInt32,
  _ callback: WnJsonCallback,
  _ userData: UnsafeMutableRawPointer?
)

@_silgen_name("wn_install_ios_background_keyring_store_with_access_group")
private func wn_install_ios_background_keyring_store_with_access_group(
  _ accessGroupPtr: UnsafePointer<UInt8>?,
  _ accessGroupLen: Int
) -> Bool

private final class BackgroundPushResultBox {
  var json: String?
}

private final class NotificationDelivery {
  private let lock = NSLock()
  private var contentHandler: ((UNNotificationContent) -> Void)?

  init(_ contentHandler: @escaping (UNNotificationContent) -> Void) {
    self.contentHandler = contentHandler
  }

  func deliver(_ content: UNNotificationContent) {
    lock.lock()
    guard let contentHandler else {
      lock.unlock()
      return
    }
    self.contentHandler = nil
    lock.unlock()
    contentHandler(content)
  }
}

private func backgroundPushJsonCallback(
  jsonPtr: UnsafePointer<UInt8>?,
  jsonLen: Int,
  userData: UnsafeMutableRawPointer?
) {
  guard let userData else { return }
  let box = Unmanaged<BackgroundPushResultBox>.fromOpaque(userData).takeUnretainedValue()
  guard let jsonPtr else {
    box.json = ""
    return
  }
  box.json = String(data: Data(bytes: jsonPtr, count: jsonLen), encoding: .utf8)
}

final class NotificationService: UNNotificationServiceExtension {
  private static let collectionQueue = DispatchQueue(
    label: "org.parres.whitenoise.notification-service.collection",
    qos: .userInitiated
  )
  private let keyringServiceId = "com.whitenoise.app"
  private let maxNotificationServiceWaitMs: UInt32 = 8_000
  private var bestAttemptDelivery: NotificationDelivery?

  override func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {
    let delivery = NotificationDelivery(contentHandler)
    bestAttemptDelivery = delivery
    NSLog("White Noise NSE received mutable notification")

    guard let content = request.content.mutableCopy() as? UNMutableNotificationContent else {
      NSLog("White Noise NSE failed to copy notification content")
      delivery.deliver(request.content)
      return
    }

    Self.collectionQueue.async {
      let shouldDisplayNotification = self.collectAndApplyNotificationText(content)
      delivery.deliver(shouldDisplayNotification ? content : UNMutableNotificationContent())
    }
  }

  override func serviceExtensionTimeWillExpire() {
    guard let bestAttemptDelivery else {
      return
    }
    NSLog("White Noise NSE timed out before rendering notification")
    bestAttemptDelivery.deliver(UNMutableNotificationContent())
  }

  private func collectAndApplyNotificationText(_ content: UNMutableNotificationContent) -> Bool {
    let collectionResult = collectNotificationsAfterPush()
    let result: BackgroundPushResult
    switch collectionResult {
    case .success(let collectedResult):
      result = collectedResult
    case .failure(let reason):
      NSLog("White Noise NSE collection failed: %@", reason)
      applyFallbackNotificationText(content)
      return true
    }

    NSLog(
      "White Noise NSE collection status=%@ count=%d error=%@",
      result.status,
      result.notifications.count,
      result.error ?? ""
    )

    guard result.status == "new_data" else {
      return false
    }

    guard let notification = result.notifications.last else {
      return false
    }

    content.title = notification.title
    content.subtitle = ""
    content.body = notification.body
    content.userInfo = content.userInfo.merging(notification.tapUserInfo) { _, new in new }
    return true
  }

  private func applyFallbackNotificationText(_ content: UNMutableNotificationContent) {
    if content.title.isEmpty {
      content.title = localized("notification_title", fallback: "White Noise")
    }
    content.subtitle = ""
    content.body = localized("notification_new_encrypted_message", fallback: "New encrypted message")
  }

  private func localized(_ key: String, fallback: String) -> String {
    NSLocalizedString(key, tableName: nil, bundle: .main, value: fallback, comment: "")
  }

  private func collectNotificationsAfterPush() -> BackgroundPushCollectionResult {
    let installed = withUtf8Buffer(keychainAccessGroup() ?? "") { accessGroupPtr, accessGroupLen in
      wn_install_ios_background_keyring_store_with_access_group(accessGroupPtr, accessGroupLen)
    }
    guard installed else {
      NSLog("White Noise NSE failed to install iOS background keyring store")
      return .failure("keyring store")
    }
    guard let container = appGroupContainerURL() else {
      NSLog("White Noise NSE App Group container unavailable")
      return .failure("app group")
    }

    let baseDir = container.appendingPathComponent("whitenoise", isDirectory: true)
    let dataDir = baseDir.appendingPathComponent("data", isDirectory: true).path
    let logsDir = baseDir.appendingPathComponent("logs", isDirectory: true).path
    try? FileManager.default.createDirectory(atPath: dataDir, withIntermediateDirectories: true)
    try? FileManager.default.createDirectory(atPath: logsDir, withIntermediateDirectories: true)

    guard let json = collectNotificationsJson(
      dataDir: dataDir,
      logsDir: logsDir,
      keyringServiceId: keyringServiceId
    ) else {
      return .failure("empty result")
    }

    do {
      return .success(try JSONDecoder().decode(BackgroundPushResult.self, from: Data(json.utf8)))
    } catch {
      NSLog("White Noise NSE notification JSON decode failed: %@", error.localizedDescription)
      return .failure("decode \(error.localizedDescription)")
    }
  }

  private func appGroupContainerURL() -> URL? {
    guard
      let identifier = Bundle.main.object(forInfoDictionaryKey: "WNAppGroupIdentifier") as? String,
      !identifier.isEmpty
    else {
      return nil
    }
    return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
  }

  private func collectNotificationsJson(
    dataDir: String,
    logsDir: String,
    keyringServiceId: String
  ) -> String? {
    let box = BackgroundPushResultBox()
    let opaque = Unmanaged.passRetained(box).toOpaque()
    defer {
      _ = Unmanaged<BackgroundPushResultBox>.fromOpaque(opaque).takeRetainedValue()
    }

    withUtf8Buffer(dataDir) { dataPtr, dataLen in
      withUtf8Buffer(logsDir) { logsPtr, logsLen in
        withUtf8Buffer(keyringServiceId) { keyringPtr, keyringLen in
          wn_collect_notifications_after_push(
            dataPtr,
            dataLen,
            logsPtr,
            logsLen,
            keyringPtr,
            keyringLen,
            maxNotificationServiceWaitMs,
            backgroundPushJsonCallback,
            opaque
          )
        }
      }
    }

    return box.json
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

private enum BackgroundPushCollectionResult {
  case success(BackgroundPushResult)
  case failure(String)
}

private struct BackgroundPushResult: Decodable {
  let status: String
  let notifications: [BackgroundNotification]
  let error: String?
}

private struct BackgroundNotification: Decodable {
  let trigger: String
  let mlsGroupId: String
  let groupName: String?
  let isDm: Bool
  let receiver: BackgroundNotificationUser
  let sender: BackgroundNotificationUser
  let content: String

  var title: String {
    if trigger == "invite" {
      if isDm {
        return sender.displayName ?? "Secure chat invite"
      }
      return groupName ?? "Secure group invite"
    }
    if isDm {
      return sender.displayName ?? "White Noise"
    }
    return groupName ?? "White Noise"
  }

  var body: String {
    let senderName = sender.displayName ?? "Someone"
    if trigger == "invite" {
      if isDm {
        return "\(senderName) invited you to a secure chat"
      }
      return "\(senderName) invited you to \(groupName ?? "a secure group")"
    }
    if isDm {
      return content
    }
    return "\(senderName): \(content)"
  }

  var tapUserInfo: [AnyHashable: Any] {
    [
      "groupId": mlsGroupId,
      "trigger": trigger,
      "receiverPubkey": receiver.pubkey,
      "mlsGroupId": mlsGroupId,
      "isInvite": trigger == "invite",
    ]
  }

  enum CodingKeys: String, CodingKey {
    case trigger
    case mlsGroupId = "mls_group_id"
    case groupName = "group_name"
    case isDm = "is_dm"
    case receiver
    case sender
    case content
  }
}

private struct BackgroundNotificationUser: Decodable {
  let pubkey: String
  let displayName: String?

  enum CodingKeys: String, CodingKey {
    case pubkey
    case displayName = "display_name"
  }
}
