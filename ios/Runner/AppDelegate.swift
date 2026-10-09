import Flutter
import UIKit
import LocalAuthentication

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "foxsecura/device", binaryMessenger: controller.binaryMessenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "audit" else { result(FlutterMethodNotImplemented); return }
      var findings = [[String: String]]()
      let context = LAContext()
      var error: NSError?
      let available = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
      if available {
        findings.append(["title": "Authentification disponible",
          "details": "Code de l’appareil ou authentification biométrique accessible.", "severity": "info"])
      } else {
        findings.append(["title": "Authentification indisponible",
          "details": "Vérifie ton code de verrouillage dans les réglages.", "severity": "warning"])
      }
      findings.append(["title": "Version iOS",
        "details": "iOS \(UIDevice.current.systemVersion). Vérifie les mises à jour dans Réglages.", "severity": "info"])
      findings.append(["title": "Portée de l’audit",
        "details": "L’isolation iOS interdit le scan arbitraire des autres applications.", "severity": "info"])
      result(["platform": "iOS \(UIDevice.current.systemVersion)", "findings": findings])
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
