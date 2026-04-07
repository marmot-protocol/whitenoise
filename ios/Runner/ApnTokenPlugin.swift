import Flutter

class ApnTokenPlugin: NSObject, FlutterPlugin {
  private static var instance: ApnTokenPlugin?
  private var channel: FlutterMethodChannel?
  private var cachedToken: String?

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "org.parres.whitenoise/apn_token",
      binaryMessenger: registrar.messenger()
    )
    let plugin = ApnTokenPlugin()
    plugin.channel = channel
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
    instance?.cachedToken = token
  }
}
