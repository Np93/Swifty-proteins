import Foundation
import SwiftUI
import SwiftData

// gestion de l'authentification (inscription, login, biométrie, changement mot de passe, suppression compte, deconnexion)
@MainActor
final class AuthStore: ObservableObject {
    @Published private(set) var session: Session?
    @Published private(set) var lastError: String?

    private let repo: AuthRepositing

    init(modelContext: ModelContext) {
        let store = AccountsStore(context: modelContext)
        let crypto = CryptoService()
        let keychain = KeychainService()
        let biometrics = BiometricsService()
        self.repo = AuthRepository(store: store, crypto: crypto, keychain: keychain, biometrics: biometrics)
    }

    var isAuthenticated: Bool { session != nil }

    func signup(username: String, password: String, enableBiometrics: Bool) {
        do {
            try repo.createAccount(username: username, password: password, enableBiometrics: enableBiometrics)
            session = Session(username: username, startedAt: .now)
            lastError = nil
        } catch { lastError = map(error) }
    }

    func loginPassword(username: String, password: String) {
        do {
            session = try repo.authenticateWithPassword(username: username, password: password)
            lastError = nil
        } catch { lastError = map(error) }
    }

    func loginBiometrics(username: String) {
        do {
            session = try repo.authenticateWithBiometrics(username: username)
            lastError = nil
        } catch { lastError = map(error) }
    }

    func canUseBiometrics(username: String) -> Bool { repo.canUseBiometrics(username: username) }

    func logout() { session = nil }

    func enableBiometrics(username: String, enabled: Bool) {
        do {
            try repo.setBiometrics(username: username, enabled: enabled)
            lastError = nil
        } catch { lastError = map(error) }
    }

	// a voir si on l'utilise
    func changePassword(username: String, oldPassword: String, newPassword: String) {
        do {
            try repo.changePassword(username: username, oldPassword: oldPassword, newPassword: newPassword)
            lastError = nil
        } catch { lastError = map(error) }
    }

    func deleteAccount(username: String) {
        do {
            try repo.deleteAccount(username: username)
            if session?.username == username { session = nil }
            lastError = nil
        } catch { lastError = map(error) }
    }

    func resetAllData() {
        do {
            try repo.purgeAll()
            session = nil
            lastError = nil
        } catch { lastError = map(error) }
    }

    private func map(_ error: Error) -> String {
        switch error {
        case AuthError.userExists: return "Ce nom d’utilisateur existe déjà"
        case AuthError.userNotFound: return "Utilisateur introuvable"
        case AuthError.invalidCredentials: return "Identifiants invalides"
        case AuthError.biometricsUnavailable: return "Biométrie indisponible"
        case let e as KeychainError: return "Erreur Keychain \(e)"
        default: return "Erreur inconnue"
        }
    }
}
