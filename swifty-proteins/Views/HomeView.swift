import SwiftUI

struct HomeView: View {
	let session: Session
	let onLogout: () -> Void
	@StateObject private var vm = LigandsViewModel()

	var body: some View {
		NavigationStack {
			VStack(spacing: 0) {
				searchBar
				List {
					Section {
						ForEach(vm.filtered, id: \.self) { ligand in
							NavigationLink(value: ligand) {
								LigandRow(name: ligand)
							}
						}
					}
				}
				.listStyle(.plain)
				.overlay {
					Group {
						if vm.isLoading && vm.items.isEmpty {
							ProgressView("Chargement…")
						} else if let err = vm.error {
							VStack(spacing: 8) {
								Image(systemName: "exclamationmark.triangle.fill")
								Text(err).font(.footnote.weight(.semibold))
							}
							.foregroundStyle(.red)
						}
					}
					.padding()
					.allowsHitTesting(false)
				}
			}
			.navigationTitle("Ligands")
			.navigationBarTitleDisplayMode(.large)
			.toolbar {
				ToolbarItem(placement: .topBarTrailing) {
					Button("Se déconnecter", role: .destructive) {
						dismissKeyboard()
						onLogout()
					}
				}
			}
			.background(Color("BackgroundColor").ignoresSafeArea())
			.tint(Color("AccentColor"))
			.scrollDismissesKeyboard(.immediately)
			.onDisappear { dismissKeyboard() }
			.navigationDestination(for: String.self) { LigandDetailView(ligand: $0) }
		}
		.task { await vm.load() }
	}

	private var searchBar: some View {
		HStack {
			Image(systemName: "magnifyingglass")
			TextField("Rechercher un ligand", text: $vm.query)
				.textInputAutocapitalization(.never)
				.disableAutocorrection(true)
		}
		.padding(.horizontal)
		.padding(.vertical, 8)
		.background(Color(.systemGray6))
	}

	private func dismissKeyboard() {
		#if canImport(UIKit)
		UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
		#endif
	}
}
