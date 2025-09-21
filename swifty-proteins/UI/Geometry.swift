import SceneKit
import UIKit

enum GeometryStyle: String, CaseIterable, Identifiable {
    case sphere
    case cube
    case spaceFilling
    var id: String { rawValue }
    var title: String {
        switch self {
        case .sphere: return "Sphérique"
        case .cube: return "Cubique"
        case .spaceFilling: return "CPK (Space-filling)"
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
        case 4: return (2, .aromatic)
        default: return (1, .normal)
        }
    }

    static func makeAtomNode(atom: LigandData.Atom, index: Int, cfg: GeometryConfig) -> SCNNode {
        let scale = cfg.scaleForSymbol(atom.symbol)
        let r = cfg.atomBaseRadius * scale

        let geometry: SCNGeometry = {
            switch cfg.style {
            case .sphere:
                let g = SCNSphere(radius: r); g.segmentCount = 48; return g
            case .cube:
                let s = r * 2
                return SCNBox(width: s, height: s, length: s, chamferRadius: r * 0.15)
            case .spaceFilling:
                // CPK: rayon = Van der Waals (Å) directement
                let vdw: CGFloat = PeriodicTable.shared.vdwRadius(for: atom.symbol) ?? 1.70
                let cpkFactor: CGFloat = 1.0
                let R: CGFloat = vdw * cpkFactor
                let g = SCNSphere(radius: R); g.segmentCount = 48; return g
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
                              cfg: GeometryConfig,
                              symA: String,
                              symB: String) -> [SCNNode] {

        if cfg.style == .spaceFilling { return [] }

        let (count, style) = visuals(for: rawOrder)

        let u = (bCenter - aCenter).normalized()
        let aTrim = endOffset(for: cfg.style, radius: aRadius, directionUnit: u)
        let bTrim = endOffset(for: cfg.style, radius: bRadius, directionUnit: -u)
        let aSurf = aCenter + u * Float(aTrim)
        let bSurf = bCenter - u * Float(bTrim)

        let perp = perpendicularUnitVector(from: aSurf, to: bSurf)

        let bondLen = CGFloat((bSurf - aSurf).length())
        let baseR   = cfg.bondBaseRadius * 0.6  // Réduire l'épaisseur de 40%
        let step    = max(baseR * (style == .aromatic ? 1.3 : 1.9), min(0.22, bondLen * 0.12))
        let rMain   = baseR * (style == .aromatic ? 0.80 : 1.00)
        let rSide   = baseR * (style == .aromatic ? 0.75 : 0.85)

        // ligand moitié–moitié (couleur de chaque atome)
        let matA = cfg.materialForSymbol(symA)
        let matB = cfg.materialForSymbol(symB)

        var nodes: [SCNNode] = []

        switch count {
        case 1:
            nodes += splitColoredBond(from: aSurf, to: bSurf, offsetVec: SCNVector3Zero,
                                      radius: rMain, matA: matA, matB: matB)

        case 2:
            let offs: [CGFloat] = [ -step * 0.5, +step * 0.5 ]
            for s in offs {
                let off = perp * Float(s)
                nodes += splitColoredBond(from: aSurf, to: bSurf, offsetVec: off,
                                          radius: rSide, matA: matA, matB: matB)
            }

        case 3:
            nodes += splitColoredBond(from: aSurf, to: bSurf, offsetVec: SCNVector3Zero,
                                      radius: rMain, matA: matA, matB: matB)
            let offs: [CGFloat] = [ -step, +step ]
            for s in offs {
                let off = perp * Float(s)
                nodes += splitColoredBond(from: aSurf, to: bSurf, offsetVec: off,
                                          radius: rSide, matA: matA, matB: matB)
            }

        default:
            nodes += splitColoredBond(from: aSurf, to: bSurf, offsetVec: SCNVector3Zero,
                                      radius: rMain, matA: matA, matB: matB)
        }

        return nodes
    }

    private static func cylinderNode(from: SCNVector3, to: SCNVector3, radius: CGFloat, material: SCNMaterial) -> SCNNode {
        let dir = to - from
        let h = CGFloat(dir.length())
        let g = SCNCylinder(radius: radius, height: h)
        g.firstMaterial = material
        let n = SCNNode(geometry: g)
        n.position = (from + to) * 0.5
        orient(node: n, along: dir)
        return n
    }

    private static func splitColoredBond(from aSurf: SCNVector3,
                                         to bSurf: SCNVector3,
                                         offsetVec: SCNVector3,
                                         radius: CGFloat,
                                         matA: SCNMaterial,
                                         matB: SCNMaterial) -> [SCNNode] {
        let p0  = aSurf + offsetVec
        let p1  = bSurf + offsetVec
        let mid = (p0 + p1) * 0.5
        let left  = cylinderNode(from: p0,  to: mid, radius: radius, material: matA)
        let right = cylinderNode(from: mid, to: p1,  radius: radius, material: matB)
        left.name = "bond"; right.name = "bond"
        return [left, right]
    }

	/* decalage dans l'offset pour eviter que les extremites soient visibles */
    private static func endOffset(for style: GeometryStyle, radius: CGFloat, directionUnit u: SCNVector3) -> CGFloat {
        switch style {
        case .sphere, .spaceFilling:
            return radius * 0.7
        case .cube:
            let half = radius * 0.7
            let ux = max(0.0001, abs(CGFloat(u.x)))
            let uy = max(0.0001, abs(CGFloat(u.y)))
            let uz = max(0.0001, abs(CGFloat(u.z)))
            return min(half/ux, min(half/uy, half/uz))
        }
    }

    private static func orient(node: SCNNode, along dir: SCNVector3) {
        let yAxis = SCNVector3(0, 1, 0)
        let axis  = yAxis.cross(dir).normalized()
        let dotv  = max(min(yAxis.normalized().dot(dir.normalized()), 1.0), -1.0)
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
