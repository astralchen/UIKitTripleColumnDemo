import UIKit
import TripleColumnDemoFeature

/// 纯 UIKit 入口：不使用 SwiftUI、storyboard 或第三方依赖。
@main
@MainActor
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     configurationForConnecting session: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "三栏示例", sessionRole: session.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
}

/// 每个窗口拥有独立的控制器和选中状态。
@MainActor
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = DefaultRouteHost()
        window.makeKeyAndVisible()
        self.window = window
    }
}
