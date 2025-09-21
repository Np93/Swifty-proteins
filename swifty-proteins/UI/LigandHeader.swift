import SwiftUI

struct ChipScroll<Data: RandomAccessCollection, Content: View>: View {
	let items: Data
	let maxHeight: CGFloat
	@ViewBuilder var content: (Data.Element) -> Content
	@Environment(\.verticalSizeClass) private var verticalSizeClass

	var body: some View {
		ScrollView(.horizontal, showsIndicators: false) {
			HStack(spacing: 6) {
				ForEach(Array(items.enumerated()), id: \.offset) { _, element in
					content(element)
				}
			}
		}
		.frame(maxHeight: maxHeight)
	}
}

struct AtomChip: View {
	let index: Int
	let atom: LigandData.Atom
	var body: some View {
		VStack(alignment: .leading, spacing: 1) {
			Text("\(index + 1). \(atom.symbol)")
			Text("x: \(atom.x), y: \(atom.y), z: \(atom.z)")
			if atom.charge != 0 { Text("Charge: \(atom.charge)") }
		}
		.font(.caption2)
		.padding(6)
		.background(Color.blue.opacity(0.1))
		.clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
	}
}

struct BondChip: View {
	let index: Int
	let bond: LigandData.Bond
	var body: some View {
		VStack(alignment: .leading, spacing: 1) {
			Text("\(index + 1). Atomes: \(bond.a1)-\(bond.a2)")
			Text("Ordre: \(bond.order)")
		}
		.font(.caption2)
		.padding(6)
		.background(Color.gray.opacity(0.1))
		.clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
	}
}

struct LigandHeader: View {
	let title: String
	let program: String
	let comment: String
	let atoms: [LigandData.Atom]
	let bonds: [LigandData.Bond]
	let docURL: URL?
	let openDoc: (URL) -> Void

	var body: some View {
		VStack(alignment: .leading, spacing: 6) {
			HStack(spacing: 6) {
				Text(title).font(.headline)
				Spacer()
				if let url = docURL {
					Button {
						openDoc(url)
					} label: {
						HStack(spacing: 4) {
							Image(systemName: "safari")
							Text("Fiche RCSB")
						}
					}
					.font(.caption.weight(.semibold))
					.buttonStyle(.borderedProminent)
				}
			}
			Text("Programme: \(program)").font(.caption)
			Text("Commentaire: \(comment)").font(.caption)
			Text("Atomes: \(atoms.count)  |  Liaisons: \(bonds.count)").font(.caption)

			if !atoms.isEmpty {
				ChipScroll(items: Array(atoms.enumerated()), maxHeight: 64) { pair in
					AtomChip(index: pair.offset, atom: pair.element)
				}
			}

			if !bonds.isEmpty {
				ChipScroll(items: Array(bonds.enumerated()), maxHeight: 48) { pair in
					BondChip(index: pair.offset, bond: pair.element)
				}
			}
		}
		.padding(8)
		.background(Color("SectionColor"))
		.clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
	}
}
