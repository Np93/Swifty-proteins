import SwiftUI
import SwiftData
import Combine

// monitor état global de l'app : sert a init l'auth (AuthStore) et gérer le feedback utilisateur (FeedbackCenter)
@MainActor
final class AppState: ObservableObject {
    @Published var auth: AuthStore?
    @Published var feedback = FeedbackCenter()

    func bootstrap(context: ModelContext) {
        guard auth == nil else { return }
        auth = AuthStore(modelContext: context)
    }

    func bindFeedback() {
        guard let auth else { return }
        auth.$session.dropFirst().sink { [weak self] session in
            guard let self else { return }
            if session != nil { self.feedback.show("Connexion réussie", style: .success) }
        }.store(in: &cancellables)
        auth.$lastError.dropFirst().sink { [weak self] err in
            guard let self, let err, !err.isEmpty else { return }
            self.feedback.show(err, style: .error)
        }.store(in: &cancellables)
    }

    private var cancellables: Set<AnyCancellable> = []
}
