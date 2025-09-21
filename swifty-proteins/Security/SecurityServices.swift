import Foundation
import CryptoKit
import LocalAuthentication
import Security

protocol BiometricsServicing {
    func isAvailable() -> Bool
}

protocol CryptoServicing {
    func randomBytes(_ count: Int) -> Data
    func hash(password: String, salt: Data, rounds: Int) -> Data
}

protocol KeychainServicing {
    func saveSecret(_ data: Data, account: String, requireBiometrics: Bool) throws
    func loadSecret(account: String, localizedReason: String?) throws -> Data
    func deleteSecret(account: String) throws
}

// CryptoKit et Security framework pour chiffrement
struct CryptoService: CryptoServicing {
    func randomBytes(_ count: Int) -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        _ = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        return Data(bytes)
    }
    func hash(password: String, salt: Data, rounds: Int = 1) -> Data {
        var data = Data()
        data.append(salt)
        data.append(password.data(using: .utf8)!)
        var digest = Data(SHA256.hash(data: data))
        if rounds > 1 {
            for _ in 1..<rounds { digest = Data(SHA256.hash(data: digest)) }
        }
        return digest
    }
}

// policies d'accès pour le keychain : biométrie ou pas
private func makeAccessControl(requireBiometrics: Bool) throws -> SecAccessControl {
    var cfError: Unmanaged<CFError>?
    let flags: SecAccessControlCreateFlags = requireBiometrics ? .biometryCurrentSet : []
    guard let ac = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenUnlockedThisDeviceOnly, flags, &cfError) else {
        if let e = cfError?.takeRetainedValue() { throw KeychainError.unknown(e) }
        throw KeychainError.accessControl
    }
    return ac
}

// Keychain: stockage sécurisé des infos sensibles (compte users id/mdp, tokens...etc) -> natifs a iOS/macOS
enum KeychainError: Error { case failure(OSStatus), accessControl, unknown(Error) }
struct KeychainService: KeychainServicing {
    func saveSecret(_ data: Data, account: String, requireBiometrics: Bool) throws {
        let access = try makeAccessControl(requireBiometrics: requireBiometrics)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrAccessControl as String: access,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.failure(status) }
    }

    func loadSecret(account: String, localizedReason: String? = nil) throws -> Data {
        let ctx = LAContext()
        if let reason = localizedReason { ctx.localizedReason = reason }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecUseAuthenticationContext as String: ctx
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { throw KeychainError.failure(status) }
        return data
    }

    func deleteSecret(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw KeychainError.failure(status) }
    }
}

// LocalAuthentication pour biométrie (FaceID/TouchID selon appareil)
struct BiometricsService: BiometricsServicing {
    func isAvailable() -> Bool {
        let ctx = LAContext()
        var err: NSError?
        return ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err)
    }
}
