import SwiftUI

private enum Theme {
    static let cardRadius: CGFloat = 12
    static let stroke = Color("OnSectionColor").opacity(0.12)
}

private struct Tag: View {
    let text: String
    var highlight = false

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(.thinMaterial, in: Capsule())
            .background(highlight ? Color.accentColor.opacity(0.15) : Color.clear, in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.1)))
    }
}

struct ChipScroll<Data: RandomAccessCollection, Content: View>: View {
	let items: Data
	let maxHeight: CGFloat
	@ViewBuilder var content: (Data.Element) -> Content
	@Environment(\.verticalSizeClass) private var verticalSizeClass

	var body: some View {
		ScrollView(.horizontal, showsIndicators: false) {
			HStack(spacing: 6) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, element in
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
        HStack(spacing: 8) {
            // pastille CPK
            Circle()
                .fill(Color(PeriodicTable.shared.color(for: atom.symbol) ?? .systemTeal))
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(index + 1). \(atom.symbol)")
                    .font(.caption.weight(.semibold))
                HStack(spacing: 8) {
                    Text("x: \(atom.x, specifier: "%.3f")")
                    Text("y: \(atom.y, specifier: "%.3f")")
                    Text("z: \(atom.z, specifier: "%.3f")")
                }
                .font(.caption2.monospaced())
                if atom.charge != 0 {
                    Tag(text: "Charge \(atom.charge)", highlight: true)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.stroke))
    }
}

struct BondChip: View {
    let index: Int
    let bond: LigandData.Bond

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbolForOrder(bond.order))
                .imageScale(.small)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(index + 1). Atomes \(bond.a1)–\(bond.a2)")
                    .font(.caption.weight(.semibold))
                HStack(spacing: 6) {
                    Tag(text: "Ordre \(bond.order)")
                }
            }
            Spacer(minLength: 0)
        }
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.stroke))
    }

    private func symbolForOrder(_ o: Int) -> String {
        switch o {
        case 2: return "equal"
        case 3: return "line.3.horizontal"
        case 4: return "rectangle.split.2x1" // aromatique (indicatif)
        default: return "minus"
        }
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
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.title3.weight(.semibold))
                Spacer()
                if let url = docURL {
                    Button {
                        openDoc(url)
                    } label: {
                        Label("Fiche RCSB", systemImage: "safari")
                            .labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }

            HStack(spacing: 12) {
                Tag(text: "Programme: \(program)")
                if !comment.isEmpty {
                    Tag(text: comment)
                }
            }

            HStack(spacing: 12) {
                Label("\(atoms.count) atomes", systemImage: "circle.grid.3x3.fill")
                    .font(.caption)
                Label("\(bonds.count) liaisons", systemImage: "link")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)

            if !atoms.isEmpty {
                ChipScroll(items: Array(atoms.enumerated()), maxHeight: 70) { pair in
                    AtomChip(index: pair.offset, atom: pair.element)
                }
            }

            if !bonds.isEmpty {
                ChipScroll(items: Array(bonds.enumerated()), maxHeight: 58) { pair in
                    BondChip(index: pair.offset, bond: pair.element)
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .strokeBorder(Theme.stroke)
        )
    }
}
