import SwiftUI

struct AnimatedIconView: View {
	private let iconName: String
	private let animationDuration: Double
	@State private var animate = false

	init(iconName: String, animationDuration: Double) {
		self.iconName = iconName
		self.animationDuration = animationDuration
	}

	var body: some View {
		Image(systemName: iconName)
			.resizable()
			.scaledToFit()
			.frame(width: 60, height: 60)
			.rotationEffect(.degrees(animate ? 360 : 0))
			.scaleEffect(animate ? 1.2 : 1.0)
			.foregroundColor(Color("AccentColor"))
			.opacity(0.65)
			.animation(.easeInOut(duration: animationDuration).repeatForever(autoreverses: true), value: animate)
			.onAppear { animate = true }
	}
}

struct SplashView: View {
	var body: some View {
		ZStack {
			LinearGradient(
				colors: [Color("BackgroundColor"), Color("AccentColor").opacity(0.2)],
				startPoint: .topLeading,
				endPoint: .bottomTrailing
			)
			.ignoresSafeArea()
			VStack(spacing: 0) {
				Spacer()
				GeometryReader { geometry in
					VStack(spacing: 0) {
						AnimatedIconView(iconName: "atom", animationDuration: 3.0)
							.frame(width: geometry.size.width * 0.3, height: geometry.size.width * 0.3)
							.frame(maxWidth: .infinity)
						Text("Swifty Proteins")
							.font(.system(size: 40, weight: .heavy))
							.tracking(2)
						Text("42 Lausanne")
							.font(.system(size: 20, weight: .light))
							.foregroundColor(Color("SubColor"))
					}
					.frame(maxWidth: .infinity)
				}
				.frame(height: 200)
				Spacer()
				Text("Copyright © 2025 cedmulle. All rights reserved.")
					.font(.footnote)
					.opacity(0.7)
					.padding(.bottom, 32)
			}
			.foregroundStyle(Color("OnBackgroundColor"))
		}
		.tint(Color("AccentColor"))
		.accessibilityHidden(true)
	}
}
