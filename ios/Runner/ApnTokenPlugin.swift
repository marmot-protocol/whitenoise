import Flutter

class ApnTokenPlugin: NSObject, FlutterPlugin {
  private static var instance: ApnTokenPlugin?
  private static var pendingToken: String?
  private var channel: FlutterMethodChannel?
  private var cachedToken: String?

  deinit {}

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "org.parres.whitenoise/apn_token",
      binaryMessenger: registrar.messenger()
    )
    let plugin = ApnTokenPlugin()
    plugin.channel = channel
    plugin.cachedToken = pendingToken
    pendingToken = nil
    registrar.addMethodCallDelegate(plugin, channel: channel)
    instance = plugin
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getToken":
      result(cachedToken)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  static func setToken(_ token: String) {
    if let inst = instance {
      inst.cachedToken = token
    } else {
      pendingToken = token
    }
  }
}
