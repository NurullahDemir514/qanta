import Flutter
import UIKit
import google_mobile_ads

class ListTileNativeAdFactory : FLTNativeAdFactory {
  func createNativeAd(_ nativeAd: GADNativeAd, customOptions: [AnyHashable : Any]? = nil) -> UIView {
    let view = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 90))
    let title = UILabel(frame: CGRect(x: 0, y: 0, width: 320, height: 20))
    title.text = nativeAd.headline
    title.font = UIFont.systemFont(ofSize: 16, weight: .medium)
    view.addSubview(title)
    return view
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  var nativeFactory: ListTileNativeAdFactory?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    nativeFactory = ListTileNativeAdFactory()
    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(self, factoryId: "listTile", nativeAdFactory: nativeFactory!)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
