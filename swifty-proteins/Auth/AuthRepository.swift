import Foundation

enum AuthError: Error { case userExists, userNotFound, invalidCredentials, biometricsUnavailable }
protocol AuthRepositing {
    func createAccount(username: String, password: String, enableBiometrics: Bool) throws
    func authenticateWithPassword(username: String, password: String) throws -> Session
    func authenticateWithBiometrics(username: String) throws -> Session
    func changePassword(username: String, oldPassword: String, newPassword: String) throws
    func setBiometrics(username: String, enabled: Bool) throws
    func deleteAccount(username: String) throws
    func canUseBiometrics(username: String) -> Bool
    func purgeAll() throws
}

// repository pattern pour l'authentification (inscription, login, biométrie, changement mot de passe, suppression compte, deconnexion)
// sert a faire le lien entre les services (store, crypto, keychain, biometrics) et la couche superieure (AuthStore)
final class AuthRepository: AuthRepositing {
    private let store: AccountsStoring
    private let crypto: CryptoServicing
    private let keychain: KeychainServicing
    private let biometrics: BiometricsServicing
    private let rounds = 1000

    init(store: AccountsStoring, crypto: CryptoServicing, keychain: KeychainServicing, biometrics: BiometricsServicing) {
        self.store = store
        self.crypto = crypto
        self.keychain = keychain
        self.biometrics = biometrics
    }

    func createAccount(username: String, password: String, enableBiometrics: Bool) throws {
        if try store.fetch(username: username) != nil { throw AuthError.userExists }
        let salt = crypto.randomBytes(32)
        let hash = crypto.hash(password: password, salt: salt, rounds: rounds)
        let user = UserAccount(username: username, salt: salt, passwordHash: hash, biometricsEnabled: enableBiometrics)
        try store.insert(user)
        let secret = crypto.randomBytes(32)
        try keychain.saveSecret(secret, account: keychainAccount(username: username), requireBiometrics: enableBiometrics)
    }

    func authenticateWithPassword(username: String, password: String) throws -> Session {
        guard let user = try store.fetch(username: username) else { throw AuthError.userNotFound }
        let candidate = crypto.hash(password: password, salt: user.salt, rounds: rounds)
        guard candidate == user.passwordHash else { throw AuthError.invalidCredentials }
        return Session(username: user.username, startedAt: .now)
    }

    func authenticateWithBiometrics(username: String) throws -> Session {
        guard let user = try store.fetch(username: username) else { throw AuthError.userNotFound }
        guard user.biometricsEnabled, biometrics.isAvailable() else { throw AuthError.biometricsUnavailable }
        _ = try keychain.loadSecret(account: keychainAccount(username: username), localizedReason: "Se connecter avec Face ID")
        return Session(username: user.username, startedAt: .now)
    }

    func changePassword(username: String, oldPassword: String, newPassword: String) throws {
        guard let user = try store.fetch(username: username) else { throw AuthError.userNotFound }
        let oldCandidate = crypto.hash(password: oldPassword, salt: user.salt, rounds: rounds)
        guard oldCandidate == user.passwordHash else { throw AuthError.invalidCredentials }
        let newSalt = crypto.randomBytes(32)
        let newHash = crypto.hash(password: newPassword, salt: newSalt, rounds: rounds)
        try store.update {
            user.salt = newSalt
            user.passwordHash = newHash
        }
    }

    func setBiometrics(username: String, enabled: Bool) throws {
        guard let user = try store.fetch(username: username) else { throw AuthError.userNotFound }
        if enabled && !biometrics.isAvailable() { throw AuthError.biometricsUnavailable }
        if enabled {
            let secret = crypto.randomBytes(32)
            try keychain.saveSecret(secret, account: keychainAccount(username: username), requireBiometrics: true)
        } else {
            try keychain.deleteSecret(account: keychainAccount(username: username))
        }
        try store.update { user.biometricsEnabled = enabled }
    }

    func deleteAccount(username: String) throws {
        guard let user = try store.fetch(username: username) else { throw AuthError.userNotFound }
        try keychain.deleteSecret(account: keychainAccount(username: username))
        try store.delete(user)
    }

    func canUseBiometrics(username: String) -> Bool {
        guard let user = try? store.fetch(username: username) else { return false }
        return user.biometricsEnabled && biometrics.isAvailable()
    }

    func purgeAll() throws {
        let all = try store.fetchAll()
        for u in all {
            try? keychain.deleteSecret(account: keychainAccount(username: u.username))
        }
        try store.deleteAll()
        clearVolatileCachesSafely()
    }

    private func keychainAccount(username: String) -> String { "swiftyproteins.\(username).secret" }

    private func clearVolatileCachesSafely() {
        URLCache.shared.removeAllCachedResponses()
        HTTPCookieStorage.shared.removeCookies(since: .distantPast)
        if #available(iOS 15.0, *) {
            URLSession.shared.getAllTasks { tasks in tasks.forEach { $0.cancel() } }
        }
    }
}
