import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene,
              let application = UIApplication.shared.delegate as? StudentDirectoryApp else { return }
        let window = UIWindow(windowScene: windowScene)
        let navigationController = UINavigationController(
            rootViewController: StudentListViewController(store: application.store)
        )
        navigationController.navigationBar.prefersLargeTitles = true
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window
    }
}
