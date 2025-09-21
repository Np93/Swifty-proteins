import SwiftUI

// modele donnee feedback
enum FeedbackStyle { case success, error }
struct FeedbackItem: Identifiable, Equatable {
	let id = UUID()
	let text: String
	let style: FeedbackStyle
}

// appel et gestion des notifs feedback (banniere en haut de l'ecran)
@MainActor
final class FeedbackCenter: ObservableObject {
	@Published var items: [FeedbackItem] = []

	func show(_ text: String, style: FeedbackStyle, duration: TimeInterval = 2.2) {
		let newItem = FeedbackItem(text: text, style: style)
		items.insert(newItem, at: 0)
		Task {
			try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
			await MainActor.run {
				withAnimation(.snappy) {
					items.removeAll { $0.id == newItem.id }
				}
			}
		}
	}

	func dismiss() {
		guard let first = items.first else { return }
		withAnimation(.snappy) { items.removeAll { $0.id == first.id } }
	}

	func dismiss(id: UUID) {
		withAnimation(.snappy) { items.removeAll { $0.id == id } }
	}
}

// vue et style de la banner de notif feedback
struct FeedbackBanner: View {
	var item: FeedbackItem
	var body: some View {
		HStack(spacing: 8) {
			Image(systemName: icon)
				.imageScale(.medium)
			Text(item.text)
				.font(.caption.weight(.semibold))
				.lineLimit(3)
				.multilineTextAlignment(.leading)
		}
		.padding(.horizontal, 12)
		.padding(.vertical, 8)
		.frame(maxWidth: 320, alignment: .leading)
		.background(background, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
		.overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color("OnSectionColor").opacity(0.15)))
		.foregroundStyle(Color("OnBackgroundColor"))
		.shadow(color: Color("OnSectionColor").opacity(0.2), radius: 10, x: 0, y: 6)
	}

	private var icon: String {
		switch item.style { case .success: "checkmark.circle.fill"; case .error: "xmark.octagon.fill" }
	}
	private var background: Color {
		switch item.style {
		case .success: .green
		case .error: .red
		}
	}
}

// animation de la presentation banner notifs
struct FeedbackPresenter: ViewModifier {
	@ObservedObject var center: FeedbackCenter
	func body(content: Content) -> some View {
		GeometryReader { proxy in
			ZStack(alignment: .bottomTrailing) {
				content
				VStack(alignment: .trailing, spacing: 8) {
					ForEach(center.items) { item in
						FeedbackBanner(item: item)
							.onTapGesture { center.dismiss(id: item.id) }
							.transition(.asymmetric(
								insertion: .move(edge: .trailing).combined(with: .opacity),
								removal: .move(edge: .trailing).combined(with: .opacity)
							))
					}
				}
				.padding(.trailing, 12)
				.padding(.bottom, proxy.safeAreaInsets.bottom)
				.zIndex(1)
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
		}
		.animation(.snappy, value: center.items)
	}
}

// affiche banniere notifs feedback en superposition de nimporte quelle vue
extension View {
	func feedbackOverlay(_ center: FeedbackCenter) -> some View {
		modifier(FeedbackPresenter(center: center))
	}
}
