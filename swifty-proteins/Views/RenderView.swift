import SwiftUI

@MainActor
final class LigandDetailViewModel: ObservableObject {
    @Published var molecules: [LigandData.Molecule] = []
    @Published var isLoading = false
    @Published var errorText: String?
    @Published var lastSource: SDFResult.Source?
    @Published var docURL: URL?

    private let repo = SDFRepository()

    func load(id: String) async {
        isLoading = true
        errorText = nil
        lastSource = nil
        docURL = nil
        defer { isLoading = false }
        do {
            let result = try await repo.fetchLigandDetailed(id: id)
            molecules = result.data.molecules
            lastSource = result.source
            docURL = result.data.docURL
        } catch {
            if let e = error as? SDFError { errorText = e.localizedDescription }
            else { errorText = error.localizedDescription }
        }
    }
}

struct LigandDetailView: View {
    let ligand: String
    @StateObject private var vm = LigandDetailViewModel()
    @StateObject private var feedback = FeedbackCenter()
    @StateObject private var web = WebSheetController()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if vm.isLoading {
                    ProgressView("Téléchargement SDF…")
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if let errorText = vm.errorText {
                    VStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(errorText).font(.footnote.weight(.semibold))
                    }
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ForEach(vm.molecules.indices, id: \.self) { idx in
                        let mol = vm.molecules[idx]

                        LigandHeader(
                            title: "Titre: \(mol.title)",
                            program: mol.program,
                            comment: mol.comment,
                            atoms: mol.atoms,
                            bonds: mol.bonds,
                            docURL: vm.docURL,
                            openDoc: { url in web.open(url) }
                        )

                        Ligand3DView(molecule: mol) { text, style in
                            feedback.show(text, style: style)
                        }

                        if !mol.properties.isEmpty {
                            Text("Propriétés (\(mol.properties.count))").font(.subheadline.weight(.semibold))
                            ScrollView {
                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(mol.properties.sorted(by: { $0.key < $1.key }), id: \.key) { k, v in
                                        Text("\(k): \(v)").font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .frame(maxHeight: 140)
                        }

                        Divider().padding(.top, 6)
                    }
                    Spacer()
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .background(Color("BackgroundColor").ignoresSafeArea())
        .navigationTitle(ligand)
        .navigationBarTitleDisplayMode(.inline)
        .feedbackOverlay(feedback)
        .sheet(isPresented: $web.isPresented) {
            if let url = vm.docURL {
                SafariView(url: url).ignoresSafeArea()
            }
        }
        .task {
            await vm.load(id: ligand)
            if let source = vm.lastSource {
                switch source {
                case .remote: feedback.show("Ligand \(ligand) chargé depuis RCSB", style: .success)
                case .bundle: feedback.show("Ligand \(ligand) chargé depuis les ressources locales", style: .success)
                }
            } else if let message = vm.errorText {
                feedback.show(message, style: .error)
            }
        }
    }
}
