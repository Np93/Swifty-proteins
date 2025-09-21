import SwiftUI
import SafariServices

final class WebSheetController: ObservableObject {
    @Published var isPresented = false
    fileprivate(set) var url: URL?

    func open(_ url: URL) {
        let scheme = url.scheme?.lowercased() ?? ""
        guard scheme == "http" || scheme == "https" else { return }
        self.url = url
        isPresented = true
    }

    func close() { isPresented = false }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let cfg = SFSafariViewController.Configuration()
        cfg.entersReaderIfAvailable = false
        let vc = SFSafariViewController(url: url, configuration: cfg)
        vc.dismissButtonStyle = .done
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
