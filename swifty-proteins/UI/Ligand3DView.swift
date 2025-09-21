import SwiftUI
import SceneKit
import UIKit

enum DisplayMode: String, CaseIterable, Identifiable {
    case normal, hBonds, exposure
    var id: String { rawValue }
    var title: String {
        switch self {
        case .normal: return "Normal"
        case .hBonds: return "Liaisons H"
        case .exposure: return "Exposure (surface)"
        }
    }
}

struct Ligand3DView: View {
    let molecule: LigandData.Molecule
    var onStatus: ((String, FeedbackStyle) -> Void)? = nil

    @State private var selectedAtomIndex: Int?
    @State private var requestShare = false
    @State private var shareURL: URL?
    @State private var presentShare = false
    @State private var showFullscreen = false
    @State private var style: GeometryStyle = .sphere
    @State private var displayMode: DisplayMode = .normal

    var body: some View {
        VStack(spacing: 8) {
            LigandControlBar(
                style: $style,
                displayMode: $displayMode,
                onShare: { requestShare = true },
                onReset: {
                    NotificationCenter.default.post(name: Ligand3DSceneView.resetCameraNote, object: nil)
                },
                onFullScreen: { showFullscreen = true }
            )
            .onChange(of: displayMode) { _, new in
                NotificationCenter.default.post(
                    name: Ligand3DSceneView.setOverlayNote,
                    object: nil,
                    userInfo: ["mode": new.rawValue]
                )
            }

            Ligand3DSceneView(
                molecule: molecule,
                selectedAtomIndex: $selectedAtomIndex,
                requestShare: $requestShare,
                style: style
            ) { url in
                shareURL = url
                requestShare = false
                if url != nil { presentShare = true }
            }
            .frame(height: 360)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .sheet(isPresented: $presentShare, onDismiss: { shareURL = nil }) {
                if let url = shareURL {
                    ActivityShareSheet(items: [url])
                        .ignoresSafeArea()
                }
            }
            .fullScreenCover(isPresented: $showFullscreen) {
                FullscreenLigand3D(molecule: molecule, style: style)
                    .ignoresSafeArea()
            }

            if let idx = selectedAtomIndex {
                AtomInfoBar(atom: molecule.atoms[idx]) {
                    selectedAtomIndex = nil
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy, value: selectedAtomIndex)
        .onAppear { onStatus?("Rendu 3D prêt", .success) }
    }
}

private struct AtomInfoBar: View {
    let atom: LigandData.Atom
    var onClose: () -> Void
    var body: some View {
        HStack(spacing: 10) {
            let info = PeriodicTable.shared.info(for: atom.symbol)
            Text("\(atom.symbol)\(info?.name != nil ? " · \(info!.name!)" : "")")
                .font(.headline)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            HStack(spacing: 8) {
                Text("x: \(atom.x, specifier: "%.3f")")
                Text("y: \(atom.y, specifier: "%.3f")")
                Text("z: \(atom.z, specifier: "%.3f")")
            }
            .font(.caption)
            if atom.charge != 0 {
                Text("Charge: \(atom.charge)")
                    .font(.caption)
            }
            Spacer(minLength: 0)
            Button(role: .cancel) { onClose() } label: {
                Image(systemName: "xmark")
                    .imageScale(.small)
                    .padding(6)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
        .padding(10)
        .background(Color("SectionColor"), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
private struct LigandControlBar: View {
    @Binding var style: GeometryStyle
    @Binding var displayMode: DisplayMode
    var onShare: () -> Void
    var onReset: () -> Void
    var onFullScreen: () -> Void

    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.verticalSizeClass) private var vSize

    var body: some View {
        Group {
            if hSize == .compact && vSize == .regular {
                // iPhone portrait : version compacte (menu + boutons)
                HStack(spacing: 8) {
                    Menu {
                        Picker("Forme", selection: $style) {
                            ForEach(GeometryStyle.allCases) { s in
                                Label(s.title, systemImage: s == .cube ? "cube" : "circle")
                                    .tag(s)
                            }
                        }
                        Picker("Vue", selection: $displayMode) {
                            ForEach(DisplayMode.allCases) { m in
                                Label(m.title, systemImage: icon(for: m)).tag(m)
                            }
                        }
                    } label: {
                        Label("Affichage", systemImage: "slider.horizontal.3")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(.thinMaterial, in: Capsule())
                    }

                    Spacer(minLength: 0)

                    Button(action: onShare) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .buttonStyle(PillIconButton())

                    Button(action: onReset) {
                        Image(systemName: "gobackward")
                    }
                    .buttonStyle(PillIconButton())

                    Button(action: onFullScreen) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                    }
                    .buttonStyle(PillIconButton())
                }
            } else {
                // iPhone paysage / iPad : version luxe (segments + boutons)
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Forme", selection: $style) {
                        ForEach(GeometryStyle.allCases) { s in
                            Text(s.title).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack(spacing: 8) {
                        Picker("Vue", selection: $displayMode) {
                            ForEach(DisplayMode.allCases) { m in
                                Text(m.title).tag(m)
                            }
                        }
                        .pickerStyle(.segmented)

                        Spacer(minLength: 0)

                        HStack(spacing: 8) {
                            Button(action: onShare) {
                                Label("Partager", systemImage: "square.and.arrow.up")
                            }
                            Button(action: onReset) {
                                Label("Reset", systemImage: "gobackward")
                            }
                            Button(action: onFullScreen) {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .imageScale(.medium)
                            }
                        }
                        .labelStyle(.iconOnly) // icônes seules pour rester compact
                        .buttonStyle(PillIconButton())
                    }
                }
            }
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12).strokeBorder(Color("OnSectionColor").opacity(0.12))
        )
    }

    private func icon(for mode: DisplayMode) -> String {
        switch mode {
        case .normal: return "eye"
        case .hBonds: return "point.3.connected.trianglepath.dotted"
        case .exposure: return "heat.waves"
        }
    }
}

// petit style de bouton pilule
private struct PillIconButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(.thinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.15)))
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

enum ImageShareWriter {
    static func writePNG(_ image: UIImage) -> URL? {
        guard let data = image.pngData() else { return nil }
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("share", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        let url = dir.appendingPathComponent("ligand-\(UUID().uuidString).png")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch { return nil }
    }

    static func watermark(_ image: UIImage, text: String) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { _ in
            image.draw(at: .zero)
            let margin: CGFloat = 16
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: max(12, min(image.size.width, image.size.height) * 0.022), weight: .semibold),
                .foregroundColor: UIColor.white.withAlphaComponent(0.9),
                .shadow: {
                    let s = NSShadow()
                    s.shadowBlurRadius = 4
                    s.shadowColor = UIColor.black.withAlphaComponent(0.55)
                    s.shadowOffset = CGSize(width: 0, height: 2)
                    return s
                }()
            ]
            let attributed = NSAttributedString(string: text, attributes: attributes)
            let size = attributed.size()
            let point = CGPoint(x: image.size.width - size.width - margin, y: image.size.height - size.height - margin)
            attributed.draw(at: point)
        }
    }
}

struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct FullscreenLigand3D: View {
    let molecule: LigandData.Molecule
    let style: GeometryStyle
    @Environment(\.dismiss) private var dismiss
    @State private var selected: Int?
    @State private var req = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.9).ignoresSafeArea()
            Ligand3DSceneView(
                molecule: molecule,
                selectedAtomIndex: $selected,
                requestShare: $req,
                style: style
            ) { _ in }
            .padding()
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24, weight: .bold))
                            .padding(12)
							.tint(.white)
                    }
                    .padding(.trailing, 12)
                    .padding(.top, 12)
                }
                Spacer()
            }
            .ignoresSafeArea(edges: .bottom)
            .padding(.top, (
                UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap { $0.windows }
                    .first { $0.isKeyWindow }?.safeAreaInsets.top ?? 0
            ))
        }
    }
}

struct Ligand3DSceneView: UIViewRepresentable {
    static let resetCameraNote = Notification.Name("Ligand3DSceneView.resetCamera")
    static let setOverlayNote  = Notification.Name("Ligand3DSceneView.setOverlay")

    let molecule: LigandData.Molecule
    @Binding var selectedAtomIndex: Int?
    @Binding var requestShare: Bool
    var style: GeometryStyle = .sphere
    let onShareReady: (URL?) -> Void

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.backgroundColor = .clear
        view.scene = SCNScene()
        view.allowsCameraControl = true
        view.defaultCameraController.interactionMode = .orbitTurntable
        view.antialiasingMode = .multisampling4X
        view.pointOfView = context.coordinator.makeCameraNode()
        view.autoenablesDefaultLighting = false
        view.isJitteringEnabled = true
        view.isTemporalAntialiasingEnabled = true
        context.coordinator.configure(view: view, with: molecule, style: style)
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.handleSetOverlay(_:)),
            name: Self.setOverlayNote,
            object: nil
        )
        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(Coordinator.resetCamera), name: Self.resetCameraNote, object: nil)
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.updateSelectionBinding = { idx in
            selectedAtomIndex = idx
        }
        if context.coordinator.currentStyle != style {
            context.coordinator.rebuild(style: style)
        }
        if requestShare {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                guard let img = context.coordinator.safeSnapshot() else {
                    onShareReady(nil)
                    return
                }
                let marked = ImageShareWriter.watermark(img, text: "cedmulle - 42swifty-companion")
                let url = ImageShareWriter.writePNG(marked)
                onShareReady(url)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(molecule: molecule)
    }

    final class Coordinator: NSObject {
        private(set) var molecule: LigandData.Molecule
        private weak var scnView: SCNView?
        private let root = SCNNode()
        private let atomRadius: CGFloat = 0.22
        private let bondRadius: CGFloat = 0.07
        private var materialCache: [String: SCNMaterial] = [:]
        private lazy var bondMaterial: SCNMaterial = {
            let m = SCNMaterial()
            m.diffuse.contents = UIColor(white: 0.75, alpha: 1.0)
            m.lightingModel = .physicallyBased
            m.metalness.contents = 0.1
            m.roughness.contents = 0.4
            return m
        }()
        var updateSelectionBinding: ((Int?) -> Void)?
        var currentStyle: GeometryStyle = .sphere

        enum OverlayMode { case none, hBonds, exposure }
        private var overlayMode: OverlayMode = .none
        private let overlayRoot = SCNNode()
        
        init(molecule: LigandData.Molecule) {
            self.molecule = molecule
        }

        func configure(view: SCNView, with mol: LigandData.Molecule, style: GeometryStyle) {
            scnView = view
            currentStyle = style
            let scene = view.scene ?? SCNScene()
            scene.rootNode.childNodes.forEach { $0.removeFromParentNode() }
            root.childNodes.forEach { $0.removeFromParentNode() }
            scene.rootNode.addChildNode(root)
            scene.rootNode.addChildNode(overlayRoot)
            addLighting(to: scene)
            buildGeometry(for: mol, style: style)
            fitCamera(resetController: true)
        }

        func rebuild(style: GeometryStyle) {
            guard let view = scnView else { return }
            currentStyle = style
            root.childNodes.forEach { $0.removeFromParentNode() }
            buildGeometry(for: molecule, style: style)
            rebuildOverlay()
            fitCamera(resetController: false)
            view.setNeedsDisplay()
        }

        func makeCameraNode() -> SCNNode {
            let cam = SCNCamera()
            cam.fieldOfView = 55
            cam.usesOrthographicProjection = false
            cam.zNear = 0.01
            cam.zFar = 1000
            let node = SCNNode()
            node.camera = cam
            node.position = SCNVector3(0, 0, 8)
            return node
        }

        private func addLighting(to scene: SCNScene) {
            let amb = SCNLight()
            amb.type = .ambient
            amb.intensity = 350
            let ambNode = SCNNode()
            ambNode.light = amb
            scene.rootNode.addChildNode(ambNode)

            let key = SCNLight()
            key.type = .directional
            key.intensity = 900
            let keyNode = SCNNode()
            keyNode.light = key
            keyNode.eulerAngles = SCNVector3(-Float.pi/4, Float.pi/4, 0)
            scene.rootNode.addChildNode(keyNode)

            let fill = SCNLight()
            fill.type = .directional
            fill.intensity = 550
            let fillNode = SCNNode()
            fillNode.light = fill
            fillNode.eulerAngles = SCNVector3(Float.pi/6, -Float.pi/3, 0)
            scene.rootNode.addChildNode(fillNode)
        }

        private func buildGeometry(for mol: LigandData.Molecule, style: GeometryStyle) {
            var atomNodes: [SCNNode] = []
            atomNodes.reserveCapacity(mol.atoms.count)

            let baseAtomR: CGFloat = (style == .spaceFilling) ? 0.35 : atomRadius
            let cfg = GeometryConfig(
                atomBaseRadius: baseAtomR,
                bondBaseRadius: bondRadius,
                style: style,
                materialForSymbol: { [weak self] sym in self?.material(for: sym) ?? SCNMaterial() },
                scaleForSymbol: { sym in PeriodicTable.shared.scale(for: sym) ?? 1.0 },
                bondMaterial: bondMaterial
            )

            for (i, a) in mol.atoms.enumerated() {
                let node = GeometryFactory.makeAtomNode(atom: a, index: i, cfg: cfg)
                root.addChildNode(node)
                atomNodes.append(node)
            }

            for b in mol.bonds {
                if currentStyle == .spaceFilling { continue }
                let i1 = max(0, min(mol.atoms.count - 1, b.a1 - 1))
                let i2 = max(0, min(mol.atoms.count - 1, b.a2 - 1))
                guard i1 != i2 else { continue }
                let n1 = atomNodes[i1].position
                let n2 = atomNodes[i2].position
                let aScale = PeriodicTable.shared.scale(for: mol.atoms[i1].symbol) ?? 1.0
                let bScale = PeriodicTable.shared.scale(for: mol.atoms[i2].symbol) ?? 1.0
                let aR = atomRadius * aScale
                let bR = atomRadius * bScale
                let symA = mol.atoms[i1].symbol
                let symB = mol.atoms[i2].symbol
                let nodes = GeometryFactory.makeBondNodes(order: b.order,
                                                          from: n1, to: n2,
                                                          aRadius: aR, bRadius: bR,
                                                          cfg: cfg,
                                                          symA: symA, symB: symB)
                nodes.forEach { root.addChildNode($0) }
            }
        }

        private func material(for symbol: String) -> SCNMaterial {
            let key = symbol.uppercased()
            if let m = materialCache[key] { return m }

            let color = PeriodicTable.shared.color(for: key) ?? UIColor.systemTeal // fallback
            let m = SCNMaterial()
            m.diffuse.contents = color
            m.metalness.contents = 0.05
            m.roughness.contents = 0.35
            m.lightingModel = .physicallyBased
            materialCache[key] = m
            return m
        }

        private func fitCamera(resetController: Bool) {
            guard let view = scnView, let camNode = view.pointOfView else { return }
            let (minV, maxV) = root.boundingBox
            let center = (minV + maxV) * 0.5
            let size = max(maxV.x - minV.x, max(maxV.y - minV.y, maxV.z - minV.z))
            let distance = Double(size) * 2.8 + 2.0
            camNode.position = SCNVector3(center.x, center.y, center.z + Float(distance))
            camNode.eulerAngles = SCNVector3Zero
            let constraint = SCNLookAtConstraint(target: root)
            constraint.isGimbalLockEnabled = true
            camNode.constraints = [constraint]
            if resetController {
                let ctrl = view.defaultCameraController
                ctrl.inertiaEnabled = true
                ctrl.interactionMode = .orbitTurntable
                ctrl.target = root.presentation.worldPosition
                ctrl.maximumVerticalAngle = 89
                ctrl.minimumVerticalAngle = -89
            }
        }

        func safeSnapshot() -> UIImage? {
            guard let v = scnView else { return nil }
            SCNTransaction.flush()
            return v.snapshot()
        }

        @objc func resetCamera() {
            fitCamera(resetController: true)
            updateSelectionBinding?(nil)
        }

        @objc func handleTap(_ gr: UITapGestureRecognizer) {
            guard let view = scnView else { return }
            let p = gr.location(in: view)
            let results = view.hitTest(p, options: [SCNHitTestOption.searchMode: SCNHitTestSearchMode.all.rawValue])
            if let atomNode = results.first(where: { $0.node.name?.hasPrefix("atom_") == true })?.node,
               let idStr = atomNode.name?.split(separator: "_").last,
               let idx = Int(idStr) {
                updateSelectionBinding?(idx)
            } else {
                updateSelectionBinding?(nil)
            }
        }
        
        @objc func handleSetOverlay(_ note: Notification) {
            guard let raw = note.userInfo?["mode"] as? String else { return }
            switch raw {
            case "normal": overlayMode = .none
            case "hBonds": overlayMode = .hBonds
            case "exposure": overlayMode = .exposure
            default: overlayMode = .none
            }
            rebuildOverlay()
        }

        private func rebuildOverlay() {
            overlayRoot.childNodes.forEach { $0.removeFromParentNode() }

            switch overlayMode {
            case .none:
                root.enumerateChildNodes { n, _ in
                    guard let name = n.name,
                          name.hasPrefix("atom_"),
                          let idStr = name.split(separator: "_").last,
                          let i = Int(idStr) else { return }
                    let sym = molecule.atoms[i].symbol.uppercased()
                    if let m = n.geometry?.firstMaterial {
                        m.emission.contents = UIColor.black
                        m.emission.intensity = 0.0
                        m.transparency = 1.0
                        // <- remets la couleur CPK initiale
                        m.diffuse.contents = PeriodicTable.shared.color(for: sym) ?? UIColor.systemTeal
                    }
                }

            case .hBonds:
                buildHBonds()

            case .exposure:
                buildExposure()
            }
        }
        
        private func isDonor(_ s: String) -> Bool {
            let u = s.uppercased()
            return u == "N" || u == "O"
        }
        private func isAcceptor(_ s: String) -> Bool {
            let u = s.uppercased()
            return u == "O" || u == "N" || u == "S"
        }

        private func buildHBonds(maxDist: Float = 3.2) {
            let atoms = molecule.atoms
            guard !atoms.isEmpty else { return }

            // positions depuis le modèle (plus robuste que lire les nodes)
            let pos: [SCNVector3] = atoms.map { SCNVector3($0.x, $0.y, $0.z) }

            let mat = SCNMaterial()
            mat.diffuse.contents = UIColor.systemTeal
            mat.emission.contents = UIColor.systemTeal
            mat.transparency = 0.85
            mat.lightingModel = .physicallyBased

            for i in 0..<atoms.count where isDonor(atoms[i].symbol) {
                let pi = pos[i]
                for j in 0..<atoms.count where j != i && isAcceptor(atoms[j].symbol) {
                    let pj = pos[j]
                    if (pj - pi).length() <= maxDist {
                        addDashedSegment(from: pi, to: pj, dash: 0.23, gap: 0.12, radius: 0.035, material: mat, parent: overlayRoot)
                    }
                }
            }
        }

        private func addDashedSegment(from a: SCNVector3, to b: SCNVector3, dash: CGFloat, gap: CGFloat, radius: CGFloat, material: SCNMaterial, parent: SCNNode) {
            let dir = (b - a); let L = CGFloat(dir.length()); guard L > 0.0001 else { return }
            let u = dir.normalized()
            var offset: CGFloat = 0
            while offset + dash <= L {
                let p0 = a + u * Float(offset)
                let p1 = a + u * Float(min(offset + dash, L))
                let seg = makeCylinder(from: p0, to: p1, radius: radius, material: material)
                seg.name = "hbond"
                parent.addChildNode(seg)
                offset += dash + gap
            }
        }

        private func makeCylinder(from: SCNVector3, to: SCNVector3, radius: CGFloat, material: SCNMaterial) -> SCNNode {
            let dir = to - from
            let h = CGFloat(dir.length())
            let g = SCNCylinder(radius: radius, height: h)
            g.firstMaterial = material
            let n = SCNNode(geometry: g)
            n.position = (from + to) * 0.5
            orient(node: n, along: dir) // <-- utilise ta méthode existante
            return n
        }
        
        private func buildExposure(neighRadius: Float = 4.0) {
            let atoms = molecule.atoms
            guard !atoms.isEmpty else { return }

            let pos: [SCNVector3] = atoms.map { SCNVector3($0.x, $0.y, $0.z) }
            var counts = [Int](repeating: 0, count: atoms.count)
            let r2 = neighRadius * neighRadius

            for i in 0..<atoms.count {
                let pi = pos[i]
                var c = 0
                for j in 0..<atoms.count where j != i {
                    let v = pos[j] - pi
                    if v.dot(v) <= r2 { c += 1 }
                }
                counts[i] = c
            }

            let minC = counts.min() ?? 0
            let maxC = counts.max() ?? 1
            let range = max(1, maxC - minC)

            // recolore les atomes (nodes "atom_i") selon exposition
            root.enumerateChildNodes { n, _ in
                guard let name = n.name, name.hasPrefix("atom_"),
                      let idStr = name.split(separator: "_").last,
                      let i = Int(idStr) else { return }
                let t = 1.0 - CGFloat(counts[i] - minC) / CGFloat(range) // 0 enterré -> 1 exposé
                let col = heatColor(t)
                if let m = n.geometry?.firstMaterial {
                    m.emission.contents = col
                    m.emission.intensity = 0.85
                    m.diffuse.contents = col.withAlphaComponent(0.65)
                    m.transparency = 0.95
                }
            }
        }

        private func heatColor(_ t: CGFloat) -> UIColor {
            let x = max(0, min(1, t))
            if x < 0.5 {
                let u = x / 0.5        // 0..1
                return UIColor(red: u, green: 0.8, blue: 1.0, alpha: 1.0)   // bleu -> cyan
            } else {
                let u = (x - 0.5) / 0.5
                return UIColor(red: 1.0, green: 0.8*(1.0-u), blue: max(0.0, 1.0 - 2.0*u), alpha: 1.0) // jaune -> rouge
            }
        }
        
        private func orient(node: SCNNode, along dir: SCNVector3) {
            let up = SCNVector3(0, 1, 0)
            let axis = up.cross(dir).normalized()
            let angle = acos(up.dot(dir.normalized()))
            if angle.isNaN { return }
            node.rotation = SCNVector4(axis.x, axis.y, axis.z, angle)
        }
    }
}

extension SCNVector3 {
    static func + (l: SCNVector3, r: SCNVector3) -> SCNVector3 { SCNVector3(l.x+r.x, l.y+r.y, l.z+r.z) }
    static func - (l: SCNVector3, r: SCNVector3) -> SCNVector3 { SCNVector3(l.x-r.x, l.y-r.y, l.z-r.z) }
    static prefix func - (v: SCNVector3) -> SCNVector3 { SCNVector3(-v.x, -v.y, -v.z) }
    static func * (v: SCNVector3, s: Float) -> SCNVector3 { SCNVector3(v.x*s, v.y*s, v.z*s) }
    func length() -> Float { sqrtf(x*x + y*y + z*z) }
    func cross(_ v: SCNVector3) -> SCNVector3 { SCNVector3(y*v.z - z*v.y, z*v.x - x*v.z, x*v.y - y*v.x) }
    func normalized() -> SCNVector3 { let l = max(length(), 1e-6); return SCNVector3(x/l, y/l, z/l) }
    func dot(_ v: SCNVector3) -> Float { x*v.x + y*v.y + z*v.z }
}
