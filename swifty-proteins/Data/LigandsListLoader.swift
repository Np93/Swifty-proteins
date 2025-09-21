import Foundation

enum LigandsLoader {
    static func load() throws -> String {
        if let url = Bundle.main.url(forResource: "ligands", withExtension: "txt") {
            return try String(contentsOf: url, encoding: .utf8)
        }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fallback = docs.appendingPathComponent("ligands.txt")
        return try String(contentsOf: fallback, encoding: .utf8)
    }
}
