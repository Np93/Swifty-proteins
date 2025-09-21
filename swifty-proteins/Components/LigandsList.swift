import SwiftUI

struct LigandRow: View {
	let name: String
	var body: some View {
		HStack {
			Text(name)
				.font(.system(.body, design: .monospaced))
				.foregroundStyle(.primary)
				.lineLimit(1)
			Spacer()
		}
		.padding(.vertical, 8)
		.contentShape(Rectangle())
	}
}
