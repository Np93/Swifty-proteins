import Foundation
import SwiftData

// modèle données utilisateur (SwiftData) : username, sel, hash du mot de passe, date de creation, biométrie activée ou pas
@Model
final class UserAccount {
    @Attribute(.unique) var username: String
    var salt: Data
    var passwordHash: Data
    var createdAt: Date
    var biometricsEnabled: Bool

    init(username: String, salt: Data, passwordHash: Data, createdAt: Date = .now, biometricsEnabled: Bool = false) {
        self.username = username
        self.salt = salt
        self.passwordHash = passwordHash
        self.createdAt = createdAt
        self.biometricsEnabled = biometricsEnabled
    }
}

struct Session: Equatable {
    let username: String
    let startedAt: Date
}

@MainActor
final class LigandsViewModel: ObservableObject {
    @Published var items: [String] = []
    @Published var query: String = ""
    @Published var isLoading = false
    @Published var error: String?

    var filtered: [String] {
        guard !query.isEmpty else { return items }
        return items.filter { $0.localizedCaseInsensitiveContains(query) }
    }

    func load() async {
        guard items.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let text = try LigandsLoader.load()
            items = text
                .split(whereSeparator: \.isNewline)
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        } catch {
            self.error = "Impossible de charger ligands.txt"
        }
    }
}
