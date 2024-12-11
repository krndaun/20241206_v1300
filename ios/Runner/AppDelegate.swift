import UIKit
import Flutter
import Firebase // Firebase 추가

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Firebase 초기화
    FirebaseApp.configure()

    // 알림 권한 요청
    UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .badge, .sound]
    ) { granted, error in
      if let error = error {
        print("알림 권한 요청 실패: \(error)")
      } else {
        print("알림 권한 요청 성공: \(granted)")
      }
    }

    // 원격 알림 등록
    application.registerForRemoteNotifications()

    // 기존 Flutter 설정 유지
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    override func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken // APNs 토큰 설정
        super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
        print("APNs Device Token: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
    }
}
