import SceneKit
import UIKit

enum GeometryStyle: String, CaseIterable, Identifiable {
    case sphere
    case cube
    case spaceFilling        // ← NEW
    var id: String { rawValue }
    var title: String {
        switch self {
        case .sphere: return "Sphérique"
        case .cube: return "Cubique"
        case .spaceFilling: return "CPK (Space-filling)"  // ← NEW
        }
    }
}

struct GeometryConfig {
    let atomBaseRadius: CGFloat
    let bondBaseRadius: CGFloat
    let style: GeometryStyle
    let materialForSymbol: (String) -> SCNMaterial
    let scaleForSymbol: (String) -> CGFloat
    let bondMaterial: SCNMaterial
}

enum GeometryFactory {
    
    private enum BondStyle { case normal, aromatic }

        private static func visuals(for rawType: Int) -> (count: Int, style: BondStyle) {
            switch rawType {
            case 1: return (1, .normal)
            case 2: return (2, .normal)
            case 3: return (3, .normal)
            case 4: return (2, .aromatic)   // standard visuel: 2 traits légèrement plus fins/rapprochés
            default: return (1, .normal)
            }
        }
    
    static func makeAtomNode(atom: LigandData.Atom, index: Int, cfg: GeometryConfig) -> SCNNode {
        let scale = cfg.scaleForSymbol(atom.symbol) // tu l’utilises déjà pour sphere/cube
        // base
        let r = cfg.atomBaseRadius * scale

        let geometry: SCNGeometry = {
            switch cfg.style {
            case .sphere:
                let g = SCNSphere(radius: r)
                g.segmentCount = 48
                return g

            case .cube:
                let s = r * 2
                return SCNBox(width: s, height: s, length: s, chamferRadius: r * 0.15)

            case .spaceFilling:
                // Rayon CPK = rayon de van der Waals en Å (directement)
                let vdw: CGFloat = PeriodicTable.shared.vdwRadius(for: atom.symbol) ?? 1.70
                // petit facteur facultatif si tu veux un rendu plus "plein"
                let cpkFactor: CGFloat = 1.0   // essaie 1.0 à 1.1
                let R: CGFloat = vdw * cpkFactor
                let g = SCNSphere(radius: R)
                g.segmentCount = 48
                return g
            }
        }()

        geometry.materials = [cfg.materialForSymbol(atom.symbol)]
        let node = SCNNode(geometry: geometry)
        node.position = SCNVector3(atom.x, atom.y, atom.z)
        node.name = "atom_\(index)"
        return node
    }

    static func makeBondNodes(order rawOrder: Int,
                              from aCenter: SCNVector3,
                              to bCenter: SCNVector3,
                              aRadius: CGFloat,
                              bRadius: CGFloat,
                              cfg: GeometryConfig) -> [SCNNode] {

        let (count, style) = visuals(for: rawOrder)

        // Direction et points de contact avec les atomes
        let u = (bCenter - aCenter).normalized()
        let aTrim = endOffset(for: cfg.style, radius: aRadius, directionUnit: u)
        let bTrim = endOffset(for: cfg.style, radius: bRadius, directionUnit: -u)
        let aSurf = aCenter + u * Float(aTrim)
        let bSurf = bCenter - u * Float(bTrim)

        // Axe perpendiculaire pour écarter les traits multiples
        let perp = perpendicularUnitVector(from: aSurf, to: bSurf)

        // Paramètres visuels
        let baseR = cfg.bondBaseRadius
        let step  = baseR * (style == .aromatic ? 1.10 : 1.80)   // écart latéral
        let rMain = baseR * (style == .aromatic ? 0.80 : 1.00)
        let rSide = baseR * (style == .aromatic ? 0.75 : 0.85)

        var nodes: [SCNNode] = []

        switch count {
        case 1:
            // simple : un trait central
            let n = cylinderNode(from: aSurf, to: bSurf, radius: rMain)
            n.geometry?.materials = [cfg.bondMaterial]
            n.name = "bond"
            nodes.append(n)

        case 2:
            // double : deux traits symétriques (pas de central)
            let offsets: [Float] = [ -Float(step)*0.5, +Float(step)*0.5 ]
            for o in offsets {
                let off = perp * o
                let n = cylinderNode(from: aSurf + off, to: bSurf + off, radius: rSide)
                n.geometry?.materials = [cfg.bondMaterial]
                n.name = "bond"
                nodes.append(n)
            }

        case 3:
            // triple : un central + deux latéraux
            // central
            do {
                let n = cylinderNode(from: aSurf, to: bSurf, radius: rMain)
                n.geometry?.materials = [cfg.bondMaterial]
                n.name = "bond"
                nodes.append(n)
            }
            // latéraux
            let offsets: [Float] = [ -Float(step), +Float(step) ]
            for o in offsets {
                let off = perp * o
                let n = cylinderNode(from: aSurf + off, to: bSurf + off, radius: rSide)
                n.geometry?.materials = [cfg.bondMaterial]
                n.name = "bond"
                nodes.append(n)
            }

        default:
            // fallback : un trait central
            let n = cylinderNode(from: aSurf, to: bSurf, radius: rMain)
            n.geometry?.materials = [cfg.bondMaterial]
            n.name = "bond"
            nodes.append(n)
        }

        return nodes
    }

    private static func endOffset(for style: GeometryStyle, radius: CGFloat, directionUnit u: SCNVector3) -> CGFloat {
        switch style {
        case .sphere, .spaceFilling:
            return radius
        case .cube:
            let half = radius
            let ux = max(0.0001, abs(CGFloat(u.x)))
            let uy = max(0.0001, abs(CGFloat(u.y)))
            let uz = max(0.0001, abs(CGFloat(u.z)))
            return min(half/ux, min(half/uy, half/uz))
        }
    }

    private static func cylinderNode(from: SCNVector3, to: SCNVector3, radius: CGFloat) -> SCNNode {
        let dir = to - from
        let h = CGFloat(dir.length())
        let g = SCNCylinder(radius: radius, height: h)
        let n = SCNNode(geometry: g)
        n.position = (from + to) * 0.5
        orient(node: n, along: dir)
        return n
    }

    private static func orient(node: SCNNode, along dir: SCNVector3) {
        let yAxis = SCNVector3(0, 1, 0)
        let axis = yAxis.cross(dir).normalized()
        let dotv = max(min(yAxis.normalized().dot(dir.normalized()), 1.0), -1.0)
        let angle = acos(dotv)
        if !angle.isNaN, angle != 0 {
            node.rotation = SCNVector4(axis.x, axis.y, axis.z, angle)
        }
    }

    private static func perpendicularUnitVector(from a: SCNVector3, to b: SCNVector3) -> SCNVector3 {
        let v = (b - a).normalized()
        let ref = abs(v.x) < 0.9 ? SCNVector3(1, 0, 0) : SCNVector3(0, 1, 0)
        return v.cross(ref).normalized()
    }
}
