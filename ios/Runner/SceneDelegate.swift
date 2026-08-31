import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    openURLContexts URLContexts: Set<UIOpenURLContext>
  ) {
    for context in URLContexts {
      _ = FirebaseAuthURLHandler.handleURL(context.url)
    }
    super.scene(scene, openURLContexts: URLContexts)
  }
}
