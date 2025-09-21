import Foundation
import SwiftData

protocol AccountsStoring {
    func fetch(username: String) throws -> UserAccount?
    func fetchAll() throws -> [UserAccount]
    func insert(_ user: UserAccount) throws
    func update(_ block: () -> Void) throws
    func delete(_ user: UserAccount) throws
    func deleteAll() throws
}

// CRUD (create, read, update, delete) sur les comptes utilisateurs (CoreData/SwiftData)
// swiftdata : stockage local des données structurées (CoreData simplifié)
final class AccountsStore: AccountsStoring {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }

    func fetch(username: String) throws -> UserAccount? {
        let descriptor = FetchDescriptor<UserAccount>(predicate: #Predicate { $0.username == username })
        return try context.fetch(descriptor).first
    }

    func fetchAll() throws -> [UserAccount] {
        try context.fetch(FetchDescriptor<UserAccount>())
    }

    func insert(_ user: UserAccount) throws {
        context.insert(user)
        try context.save()
    }

    func update(_ block: () -> Void) throws {
        block()
        try context.save()
    }

    func delete(_ user: UserAccount) throws {
        context.delete(user)
        try context.save()
    }

    func deleteAll() throws {
        let users = try fetchAll()
        users.forEach { context.delete($0) }
        try context.save()
    }
}