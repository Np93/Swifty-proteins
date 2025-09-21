import UIKit

/*
    Plus de definitions en dur pour la table periodique
    Toute les datas sont chargees depuis un PeriodicTable.json
*/
public struct ElementInfo: Hashable {
    public let symbol: String
    public let name: String?
    public let cpkColor: UIColor?
    public let vdwRadiusAngstrom: CGFloat?
    public let atomicMass: Double?
    public let category: String?
    public let number: Int?
    public let group: Int?
    public let period: Int?
    public let density: Double?
    public let melt: Double?
    public let boil: Double?
    public let electronAffinity: Double?
    public let electronegativityPauling: Double?
    public let ionizationEnergies: [Double]?
    public let summary: String?
    public let sourceURL: String?
    public let block: String?
    public let appearance: String?
    public let shells: [Int]?
    public let electronConfiguration: String?
    public let electronConfigurationSemantic: String?
    public let imageTitle: String?
    public let imageURL: String?

    public var displayName: String { name ?? symbol }
}

public final class PeriodicTable {
    public static let shared = PeriodicTable()
    private let map: [String: ElementInfo]

    private init() {
        self.map = Self.loadFromJSON() ?? [:]
    }

    public func info(for symbol: String) -> ElementInfo? {
        map[symbol.uppercased()]
    }

    public func color(for symbol: String) -> UIColor? {
        info(for: symbol)?.cpkColor
    }

    public func vdwRadius(for symbol: String) -> CGFloat? {
        info(for: symbol)?.vdwRadiusAngstrom
    }

    public func scale(for symbol: String) -> CGFloat? {
        1.0
    }

    public func all() -> [ElementInfo] {
        Array(map.values)
    }
}

private extension PeriodicTable {
    struct Root: Decodable {
        let elements: [Element]
    }

    struct ElementImage: Decodable {
        let title: String?
        let url: String?
        let attribution: String?
    }

    struct Element: Decodable {
        let name: String?
        let appearance: String?
        let atomic_mass: Double?
        let boil: Double?
        let category: String?
        let density: Double?
        let discovered_by: String?
        let melt: Double?
        let molar_heat: Double?
        let named_by: String?
        let number: Int?
        let period: Int?
        let group: Int?
        let phase: String?
        let source: String?
        let spectral_img: String?
        let summary: String?
        let symbol: String
        let xpos: Int?
        let ypos: Int?
        let wxpos: Int?
        let wypos: Int?
        let shells: [Int]?
        let electron_configuration: String?
        let electron_configuration_semantic: String?
        let electron_affinity: Double?
        let electronegativity_pauling: Double?
        let ionization_energies: [Double]?
        let cpk_hex: String?
        let image: ElementImage?
        let block: String?
        let bohr_model_image: String?
        let bohr_model_3d: String?
        let van_der_waal_radius: Double?
        let van_der_waals_radius: Double?

        enum CodingKeys: String, CodingKey {
            case name, appearance, atomic_mass, boil, category, density, discovered_by, melt, molar_heat, named_by, number, period, group, phase, source, spectral_img, summary, symbol, xpos, ypos, wxpos, wypos, shells, electron_configuration, electron_configuration_semantic, electron_affinity, electronegativity_pauling, ionization_energies, image, block, bohr_model_image, bohr_model_3d
            case cpk_hex = "cpk-hex"
            case van_der_waal_radius = "van_der_waal_radius"
            case van_der_waals_radius = "van_der_waals_radius"
        }
    }

    static func loadFromJSON() -> [String: ElementInfo]? {
        guard let url = Bundle.main.url(forResource: "PeriodicTable", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        guard let root = try? decoder.decode(Root.self, from: data) else { return nil }

        var out: [String: ElementInfo] = [:]
        out.reserveCapacity(root.elements.count)

        for e in root.elements {
            let sym = e.symbol.uppercased()
            let color = UIColor(hexString: e.cpk_hex)
            let vdwA = normalizeVDW(e.van_der_waal_radius ?? e.van_der_waals_radius)
            let info = ElementInfo(
                symbol: sym,
                name: e.name,
                cpkColor: color,
                vdwRadiusAngstrom: vdwA,
                atomicMass: e.atomic_mass,
                category: e.category,
                number: e.number,
                group: e.group,
                period: e.period,
                density: e.density,
                melt: e.melt,
                boil: e.boil,
                electronAffinity: e.electron_affinity,
                electronegativityPauling: e.electronegativity_pauling,
                ionizationEnergies: e.ionization_energies,
                summary: e.summary,
                sourceURL: e.source,
                block: e.block,
                appearance: e.appearance,
                shells: e.shells,
                electronConfiguration: e.electron_configuration,
                electronConfigurationSemantic: e.electron_configuration_semantic,
                imageTitle: e.image?.title,
                imageURL: e.image?.url
            )
            out[sym] = info
        }

        return out
    }

    static func normalizeVDW(_ raw: Double?) -> CGFloat? {
        guard let r = raw else { return nil }
        if r > 10 {
            return CGFloat(r) / 100.0
        } else {
            return CGFloat(r)
        }
    }
}

private extension UIColor {
    convenience init?(hexString: String?) {
        guard let hexString = hexString else { return nil }
        let cleaned = hexString.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        guard cleaned.count == 6 || cleaned.count == 8 else { return nil }
        var hex: UInt64 = 0
        guard Scanner(string: cleaned).scanHexInt64(&hex) else { return nil }
        let hasAlpha = cleaned.count == 8
        let r = CGFloat((hex >> (hasAlpha ? 24 : 16)) & 0xFF) / 255.0
        let g = CGFloat((hex >> (hasAlpha ? 16 : 8)) & 0xFF) / 255.0
        let b = CGFloat((hex >> (hasAlpha ? 8 : 0)) & 0xFF) / 255.0
        let a = hasAlpha ? CGFloat(hex & 0xFF) / 255.0 : 1.0
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}
