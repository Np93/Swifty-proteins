import Foundation

// nettoyage des fichiers temporaires au prochain lancement de l'app
enum StartupCleanup {
    private static let key = "needs_temp_cleanup"
    static func scheduleTempCleanupOnNextLaunch() { UserDefaults.standard.set(true, forKey: key) }
    static func runIfNeeded() {
        guard UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.removeObject(forKey: key)
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        if let items = try? FileManager.default.contentsOfDirectory(at: tmp, includingPropertiesForKeys: nil) {
            for url in items { try? FileManager.default.removeItem(at: url) }
        }
    }
}
