import Foundation

struct LigandData: Hashable {
    struct Atom: Hashable {
        let x: Double
        let y: Double
        let z: Double
        let symbol: String
        let charge: Int
    }
    struct Bond: Hashable {
        let a1: Int
        let a2: Int
        let order: Int
    }
    struct Molecule: Hashable {
        let title: String
        let program: String
        let comment: String
        let atoms: [Atom]
        let bonds: [Bond]
        let properties: [String: String]
    }
    let id: String
    let molecules: [Molecule]
    let docURL: URL
}

enum SDFParser {
    static func parse(_ text: String, id: String) throws -> LigandData {
        let rawBlocks = text.components(separatedBy: "$$$$")
        let blocks = rawBlocks
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !blocks.isEmpty else { throw SDFError.parse("Vide") }
        var mols: [LigandData.Molecule] = []
        mols.reserveCapacity(blocks.count)
        for block in blocks { mols.append(try parseSingleMol(block)) }
        let url = URL(string: "https://www.rcsb.org/ligand/\(id.uppercased())")!
        return LigandData(id: id, molecules: mols, docURL: url)
    }

    private static func parseSingleMol(_ s: String) throws -> LigandData.Molecule {
        var lines = s.components(separatedBy: .newlines).map { $0.replacingOccurrences(of: "\r", with: "") }
        while lines.last?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true { lines.removeLast() }
        guard lines.count >= 4 else { throw SDFError.parse("Counts line invalide") }
        let title = lines.removeFirst()
        let program = lines.removeFirst()
        let comment = lines.removeFirst()
        let counts = lines.removeFirst()
        guard let (natoms, nbonds) = parseCountsLine(counts) else { throw SDFError.parse("Counts line invalide") }
        guard lines.count >= natoms else { throw SDFError.parse("Ligne atome invalide") }
        var atoms: [LigandData.Atom] = []
        atoms.reserveCapacity(natoms)
        for i in 0..<natoms {
            guard let a = parseAtomLine(lines[i]) else { throw SDFError.parse("Ligne atome \(i+1) invalide") }
            atoms.append(a)
        }
        guard lines.count >= natoms + nbonds else { throw SDFError.parse("Ligne liaison invalide") }
        var bonds: [LigandData.Bond] = []
        bonds.reserveCapacity(nbonds)
        for j in 0..<nbonds {
            guard let b = parseBondLine(lines[natoms + j]) else { throw SDFError.parse("Ligne liaison \(j+1) invalide") }
            bonds.append(b)
        }
        var idx = natoms + nbonds
        var sawMEnd = false
        while idx < lines.count {
            let line = lines[idx].trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("M  END") { sawMEnd = true; idx += 1; break }
            idx += 1
        }
        guard sawMEnd else { throw SDFError.parse("M  END manquant") }
        var props: [String: String] = [:]
        while idx < lines.count {
            let raw = lines[idx]
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix(">") {
                if let name = extractPropertyName(line) {
                    idx += 1
                    var values: [String] = []
                    while idx < lines.count {
                        let v = lines[idx]
                        if v.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { break }
                        if v.trimmingCharacters(in: .whitespaces).hasPrefix(">") { break }
                        values.append(v)
                        idx += 1
                    }
                    props[name] = values.joined(separator: "\n")
                } else {
                    idx += 1
                }
            } else {
                idx += 1
            }
        }
        return LigandData.Molecule(title: title, program: program, comment: comment, atoms: atoms, bonds: bonds, properties: props)
    }

    private static func parseCountsLine(_ s: String) -> (Int, Int)? {
        let trimmed = s.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        let parts = trimmed.split { $0 == " " || $0 == "\t" }.map(String.init)
        guard parts.count >= 2, let a = Int(parts[0]), let b = Int(parts[1]) else { return nil }
        return (a, b)
    }

    private static func parseAtomLine(_ s: String) -> LigandData.Atom? {
        let p = s.split { $0 == " " || $0 == "\t" }.map(String.init)
        guard p.count >= 4 else { return nil }
        guard let x = Double(p[0]), let y = Double(p[1]), let z = Double(p[2]) else { return nil }
        let sym = p[3]
        var charge = 0
        if p.count >= 7, let code = Int(p[6]) {
            switch code {
            case 1: charge = 3
            case 2: charge = 2
            case 3: charge = 1
            case 5: charge = -1
            case 6: charge = -2
            case 7: charge = -3
            default: charge = 0
            }
        }
        return LigandData.Atom(x: x, y: y, z: z, symbol: sym, charge: charge)
    }

    private static func parseBondLine(_ s: String) -> LigandData.Bond? {
        let p = s.split { $0 == " " || $0 == "\t" }.map(String.init)
        guard p.count >= 3, let a1 = Int(p[0]), let a2 = Int(p[1]), let order = Int(p[2]) else { return nil }
        return LigandData.Bond(a1: a1, a2: a2, order: order)
    }

    private static func extractPropertyName(_ line: String) -> String? {
        guard let start = line.firstIndex(of: "<"), let end = line.firstIndexAfter(start, of: ">") else { return nil }
        return String(line[line.index(after: start)..<end])
    }
}

extension String {
    func firstIndexAfter(_ i: Index, of ch: Character) -> Index? {
        var j = index(after: i)
        while j < endIndex {
            if self[j] == ch { return j }
            j = index(after: j)
        }
        return nil
    }
}
