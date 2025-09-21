import SwiftUI

// confidentialite de l'app : proteger les infos sensibles a l'ecran si perte de focus
@MainActor
final class AppSecurity: ObservableObject {
    @Published private(set) var isShieldVisible = false
    private var sensitiveDepth = 0
    private var lockTask: Task<Void, Never>?
    private let lockDelay: Duration = .seconds(1)
    weak var auth: AuthStore?

    func attach(_ auth: AuthStore) { self.auth = auth }

    func beginSensitive() {
        sensitiveDepth += 1
        isShieldVisible = false
        cancelLock()
    }

    func endSensitive() {
        if sensitiveDepth > 0 { sensitiveDepth -= 1 }
        if sensitiveDepth == 0 { isShieldVisible = false }
    }

    func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            isShieldVisible = false
            cancelLock()
        case .inactive:
            if sensitiveDepth == 0 { isShieldVisible = true }
        case .background:
            isShieldVisible = true
            scheduleLock()
        @unknown default:
            scheduleLock()
        }
    }

    private func scheduleLock() {
        cancelLock()
        lockTask = Task { [weak self] in
            try? await Task.sleep(for: self?.lockDelay ?? .seconds(1))
            self?.auth?.logout()
            self?.isShieldVisible = true
        }
    }

    private func cancelLock() {
        lockTask?.cancel()
        lockTask = nil
    }
}
