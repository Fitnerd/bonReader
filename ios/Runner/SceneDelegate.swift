import Flutter
import UIKit

/// Pendant zu `FLAG_SECURE` auf Android (siehe `MainActivity.kt`):
///
/// iOS legt beim Hintergrund-Wechsel ein Snapshot der App in
/// `~/Library/Caches/Snapshots/<bundle-id>/...` ab — fuer den
/// App-Switcher-Vorschau. Ohne Schutz waeren da alle aktuell
/// sichtbaren Betraege, Bons und Budgets im Klartext drauf, der
/// Snapshot ueberlebt App-Restarts und kann ueber iCloud-Backup-
/// Restore auf andere Geraete gelangen.
///
/// Mitigation: bei `sceneWillResignActive` ein blickdichtes Overlay
/// auf das Window legen, das die UI verdeckt, bevor iOS den
/// Snapshot zieht. Bei `sceneDidBecomeActive` wieder entfernen.
class SceneDelegate: FlutterSceneDelegate {

  /// Privacy-Overlay, das beim Hintergrund-Wechsel eingeblendet wird.
  /// Wird per `tag` zusaetzlich identifiziert, falls bei einer
  /// View-Hierarchy-Aenderung doch mal die Referenz verloren geht.
  private var privacyOverlay: UIView?
  private static let privacyOverlayTag = 0xB07B07

  override func sceneWillResignActive(_ scene: UIScene) {
    super.sceneWillResignActive(scene)
    addPrivacyOverlay(for: scene)
  }

  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    removePrivacyOverlay(for: scene)
  }

  // MARK: - Overlay

  private func addPrivacyOverlay(for scene: UIScene) {
    guard let window = self.window ?? targetWindow(for: scene) else {
      return
    }
    // Bereits aktiv? Nichts zu tun.
    if window.viewWithTag(SceneDelegate.privacyOverlayTag) != nil {
      return
    }

    let overlay = UIView(frame: window.bounds)
    overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    overlay.tag = SceneDelegate.privacyOverlayTag
    // Brandfarbe (BonBudget-Blau, identisch zum Splash). Wenn spaeter
    // ein Asset-Set fuer den Splash dazukommt, hier ueber `UIImageView`
    // ersetzen — die Funktion bleibt dieselbe.
    overlay.backgroundColor = UIColor(
      red: 0x1F / 255.0,
      green: 0x6F / 255.0,
      blue: 0xEB / 255.0,
      alpha: 1.0
    )

    let label = UILabel()
    label.text = "BonBudget"
    label.font = UIFont.boldSystemFont(ofSize: 28)
    label.textColor = .white
    label.translatesAutoresizingMaskIntoConstraints = false
    overlay.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
    ])

    window.addSubview(overlay)
    window.bringSubviewToFront(overlay)
    privacyOverlay = overlay
  }

  private func removePrivacyOverlay(for scene: UIScene) {
    if let overlay = privacyOverlay {
      overlay.removeFromSuperview()
    }
    // Falls die `tag`-Suche eine Restkopie findet (z. B. nach
    // Configuration-Reload): auch die wegnehmen.
    if let window = self.window ?? targetWindow(for: scene),
       let stale = window.viewWithTag(SceneDelegate.privacyOverlayTag) {
      stale.removeFromSuperview()
    }
    privacyOverlay = nil
  }

  /// Fallback fuer den Fall, dass `self.window` zum Zeitpunkt von
  /// `sceneWillResignActive` (noch) nicht gesetzt ist — das passiert
  /// in seltenen Lifecycle-Edge-Cases (z. B. Multi-Scene-Konfig auf
  /// iPad). Wir ziehen das erste Window aus der Scene direkt.
  private func targetWindow(for scene: UIScene) -> UIWindow? {
    guard let windowScene = scene as? UIWindowScene else { return nil }
    return windowScene.windows.first
  }
}
