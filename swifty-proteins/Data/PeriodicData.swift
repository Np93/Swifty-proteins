import UIKit

struct ElementInfo: Hashable {
    let symbol: String
    let name: String?
    let cpk: UIColor
    let radiusScale: CGFloat
}

final class PeriodicTable {
    static let shared = PeriodicTable()
    private let map: [String: ElementInfo]

    private init() {
        var m: [String: ElementInfo] = [:]
        func add(_ s: String, _ name: String, _ c: UIColor, _ scale: CGFloat) { m[s] = ElementInfo(symbol: s, name: name, cpk: c, radiusScale: scale) }

        add("H","Hydrogen", .white, 0.7)
        add("C","Carbon", UIColor(white: 0.2, alpha: 1), 1.0)
        add("N","Nitrogen", UIColor(red: 0.188, green: 0.314, blue: 0.973, alpha: 1), 0.95)
        add("O","Oxygen", UIColor(red: 1, green: 0.051, blue: 0.051, alpha: 1), 0.9)
        add("F","Fluorine", UIColor(red: 0.565, green: 0.878, blue: 0.314, alpha: 1), 0.9)
        add("CL","Chlorine", UIColor(red: 0.122, green: 0.941, blue: 0.122, alpha: 1), 0.9)
        add("BR","Bromine", UIColor(red: 0.651, green: 0.161, blue: 0.161, alpha: 1), 1.0)
        add("I","Iodine", UIColor(red: 0.580, green: 0, blue: 0.580, alpha: 1), 1.05)
        add("HE","Helium", UIColor(red: 0.565, green: 0.878, blue: 0.941, alpha: 1), 0.8)
        add("NE","Neon", UIColor(red: 0.565, green: 0.878, blue: 0.941, alpha: 1), 0.8)
        add("AR","Argon", UIColor(red: 0.565, green: 0.878, blue: 0.941, alpha: 1), 0.9)
        add("XE","Xenon", UIColor(red: 0.565, green: 0.878, blue: 0.941, alpha: 1), 1.0)
        add("KR","Krypton", UIColor(red: 0.565, green: 0.878, blue: 0.941, alpha: 1), 0.95)
        add("P","Phosphorus", UIColor(red: 1, green: 0.502, blue: 0, alpha: 1), 1.1)
        add("S","Sulfur", UIColor(red: 1, green: 1, blue: 0.188, alpha: 1), 1.05)
        add("B","Boron", UIColor(red: 1, green: 0.710, blue: 0.710, alpha: 1), 0.9)
        add("LI","Lithium", UIColor(red: 0.439, green: 0.188, blue: 0.773, alpha: 1), 1.1)
        add("NA","Sodium", UIColor(red: 0.439, green: 0.188, blue: 0.773, alpha: 1), 1.15)
        add("K","Potassium", UIColor(red: 0.439, green: 0.188, blue: 0.773, alpha: 1), 1.25)
        add("RB","Rubidium", UIColor(red: 0.439, green: 0.188, blue: 0.773, alpha: 1), 1.3)
        add("CS","Cesium", UIColor(red: 0.439, green: 0.188, blue: 0.773, alpha: 1), 1.35)
        add("FR","Francium", UIColor(red: 0.439, green: 0.188, blue: 0.773, alpha: 1), 1.35)
        add("BE","Beryllium", UIColor(red: 0, green: 0.502, blue: 0, alpha: 1), 0.9)
        add("MG","Magnesium", UIColor(red: 0, green: 0.502, blue: 0, alpha: 1), 1.0)
        add("CA","Calcium", UIColor(red: 0, green: 0.502, blue: 0, alpha: 1), 1.1)
        add("SR","Strontium", UIColor(red: 0, green: 0.502, blue: 0, alpha: 1), 1.2)
        add("BA","Barium", UIColor(red: 0, green: 0.502, blue: 0, alpha: 1), 1.25)
        add("RA","Radium", UIColor(red: 0, green: 0.502, blue: 0, alpha: 1), 1.3)
        add("TI","Titanium", UIColor(red: 0.749, green: 0.761, blue: 0.780, alpha: 1), 1.05)
        add("FE","Iron", UIColor(red: 0.878, green: 0.400, blue: 0.200, alpha: 1), 1.05)
        add("AL","Aluminum", UIColor(red: 0.749, green: 0.651, blue: 0.651, alpha: 1), 1.05)
        add("SI","Silicon", UIColor(red: 0.941, green: 0.784, blue: 0.627, alpha: 1), 1.0)
        add("CU","Copper", UIColor(red: 0.784, green: 0.502, blue: 0.2, alpha: 1), 1.05)
        add("ZN","Zinc", UIColor(red: 0.490, green: 0.502, blue: 0.690, alpha: 1), 1.05)
        add("CO","Cobalt", UIColor(red: 0.941, green: 0.565, blue: 0.627, alpha: 1), 1.05)
        add("NI","Nickel", UIColor(red: 0.314, green: 0.816, blue: 0.314, alpha: 1), 1.05)
        add("MN","Manganese", UIColor(red: 0.612, green: 0.478, blue: 0.780, alpha: 1), 1.05)
        add("CR","Chromium", UIColor(red: 0.541, green: 0.780, blue: 0.780, alpha: 1), 1.05)
        add("V","Vanadium", UIColor(red: 0.651, green: 0.651, blue: 0.671, alpha: 1), 1.05)
        add("W","Tungsten", UIColor(red: 0.129, green: 0.580, blue: 0.839, alpha: 1), 1.05)
        add("MO","Molybdenum", UIColor(red: 0.329, green: 0.710, blue: 0.710, alpha: 1), 1.05)
        add("SN","Tin", UIColor(red: 0.651, green: 0.651, blue: 0.675, alpha: 1), 1.1)
        add("PB","Lead", UIColor(red: 0.341, green: 0.341, blue: 0.380, alpha: 1), 1.2)
        add("HG","Mercury", UIColor(red: 0.722, green: 0.722, blue: 0.816, alpha: 1), 1.1)
        add("AG","Silver", UIColor(red: 0.753, green: 0.753, blue: 0.753, alpha: 1), 1.1)
        add("AU","Gold", UIColor(red: 1.0, green: 0.820, blue: 0.137, alpha: 1), 1.1)
        add("PT","Platinum", UIColor(red: 0.816, green: 0.816, blue: 0.878, alpha: 1), 1.1)
        add("PD","Palladium", UIColor(red: 0.702, green: 0.702, blue: 0.753, alpha: 1), 1.1)
        add("SE","Selenium", UIColor(red: 1.0, green: 0.631, blue: 0.0, alpha: 1), 1.0)
        add("TE","Tellurium", UIColor(red: 0.831, green: 0.478, blue: 0.0, alpha: 1), 1.05)
        add("AS","Arsenic", UIColor(red: 0.741, green: 0.502, blue: 0.890, alpha: 1), 1.0)

        map = m
    }

    func color(for symbol: String) -> UIColor {
        let key = symbol.uppercased()
        if let e = map[key] { return e.cpk }
        return UIColor.systemTeal
    }

    func info(for symbol: String) -> ElementInfo? {
        map[symbol.uppercased()]
    }

    func scale(for symbol: String) -> CGFloat? {
        map[symbol.uppercased()]?.radiusScale
    }
}

extension PeriodicTable {
    func vdwRadius(for symbol: String) -> CGFloat {
        switch symbol.uppercased() {
        case "H":  return 1.20
        case "C":  return 1.70
        case "N":  return 1.55
        case "O":  return 1.52
        case "F":  return 1.47
        case "P":  return 1.80
        case "S":  return 1.80
        case "CL": return 1.75
        case "BR": return 1.85
        case "I":  return 1.98
        default:   return 1.70
        }
    }
}
