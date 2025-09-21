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
                // ↑ CPK : rayon proportionnel au VDW
                let vdw = PeriodicTable.shared.vdwRadius(for: atom.symbol) // en Å
                // normalise sur C=1.70 et booste un peu (×1.6) pour un rendu "plein"
                let cpkScale = (vdw / 1.70) * 1.6
                let R = cfg.atomBaseRadius * cpkScale
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

    static func makeBondNodes(order: Int,
                              from aCenter: SCNVector3,
                              to bCenter: SCNVector3,
                              aRadius: CGFloat,
                              bRadius: CGFloat,
                              cfg: GeometryConfig) -> [SCNNode] {
        var nodes: [SCNNode] = []
        let u = (bCenter - aCenter).normalized()
        let aTrim = endOffset(for: cfg.style, radius: aRadius, directionUnit: u)
        let bTrim = endOffset(for: cfg.style, radius: bRadius, directionUnit: -u)
        let aSurf = aCenter + u * Float(aTrim)
        let bSurf = bCenter - u * Float(bTrim)

        let main = cylinderNode(from: aSurf, to: bSurf, radius: cfg.bondBaseRadius)
        main.geometry?.materials = [cfg.bondMaterial]
        main.name = "bond"
        if order <= 1 { return [main] }
        nodes.append(main)

        let offsetAxis = perpendicularUnitVector(from: aSurf, to: bSurf) * Float(cfg.bondBaseRadius * 1.8)
        let count = order
        let start = -(count - 1) / 2
        for t in 0..<count {
            if t == (count / 2) { continue }
            let o = offsetAxis * Float(t + start)
            let extra = cylinderNode(from: aSurf + o, to: bSurf + o, radius: cfg.bondBaseRadius * 0.85)
            extra.geometry?.materials = [cfg.bondMaterial]
            extra.name = "bond"
            nodes.append(extra)
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
