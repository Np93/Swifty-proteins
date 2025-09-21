import Foundation

struct SDFResult {
    enum Source { case remote, bundle }
    let data: LigandData
    let source: Source
}

enum SDFError: Error, LocalizedError {
    case notFound
    case network(String)
    case invalidData
    case parse(String)

    var errorDescription: String? {
        switch self {
        case .notFound: return "Fichier SDF introuvable (404)"
        case .network(let m): return "Erreur réseau: \(m)"
        case .invalidData: return "Données SDF invalides"
        case .parse(let m): return "Erreur de parsing: \(m)"
        }
    }
}

protocol SDFRepositing {
    func fetchLigand(id: String) async throws -> LigandData
}

final class SDFRepository: SDFRepositing {
    private let session: URLSession
    private let base = "https://files.rcsb.org/ligands/download"

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchLigand(id: String) async throws -> LigandData {
        let result = try await fetchLigandDetailed(id: id)
        return result.data
    }

	// ordre d'appel : d'abord le site en remote, fallback sur bundle local si erreur (404, 503...etc)
    func fetchLigandDetailed(id: String) async throws -> SDFResult {
        do {
            return try await fetchFromRemote(id: id)
        } catch let netErr {
			print("Fetch remote error: \(netErr.localizedDescription)")
			print("Falling back to bundle.")
            if let fromBundle = try? fetchFromBundle(id: id) { return fromBundle }
            if let e = netErr as? SDFError { throw e }
			print("Also failed to load from bundle.")
            throw SDFError.network(netErr.localizedDescription)
        }
    }

    func fetchFromRemote(id: String) async throws -> SDFResult {
        let url = URL(string: "\(base)/\(id)_ideal.sdf")!
        let (data, resp) = try await session.data(from: url)
        if let http = resp as? HTTPURLResponse, http.statusCode == 404 { throw SDFError.notFound }
        guard (resp as? HTTPURLResponse)?.statusCode ?? 200 < 300 else {
            throw SDFError.network("HTTP \((resp as? HTTPURLResponse)?.statusCode ?? -1)")
        }
        guard let text = decode(data) else { throw SDFError.invalidData }
        do {
            let parsed = try SDFParser.parse(text, id: id)
            return SDFResult(data: parsed, source: .remote)
        } catch {
            throw SDFError.parse(error.localizedDescription)
        }
    }

    func fetchFromBundle(id: String) throws -> SDFResult {
        let text = try bundleLoad(id: id)
        do {
            let parsed = try SDFParser.parse(text, id: id)
            return SDFResult(data: parsed, source: .bundle)
        } catch {
            throw SDFError.parse(error.localizedDescription)
        }
    }

    private func decode(_ data: Data) -> String? {
        String(data: data, encoding: .utf8)
        ?? String(data: data, encoding: .ascii)
        ?? String(data: data, encoding: .isoLatin1)
    }

    private func bundleLoad(id: String) throws -> String {
        let candidates = [id, id.uppercased(), id.lowercased()]
        for name in candidates {
            if let url = Bundle.main.url(forResource: name, withExtension: "sdf"),
               let s = try? String(contentsOf: url, encoding: .utf8) {
                return s
            }
        }
        throw SDFError.notFound
    }
}
