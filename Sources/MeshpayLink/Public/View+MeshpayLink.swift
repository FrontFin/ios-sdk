#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import UIKit

public extension View {
    /// Presents MeshPay Link full screen while `isPresented` is `true`.
    ///
    /// ```swift
    /// .meshpayLink(
    ///     isPresented: $showLink,
    ///     token: token,
    ///     clientId: clientId,
    ///     options: LinkOptions(theme: .system),
    ///     onExit: { summary in showLink = false },
    ///     onError: { _ in showLink = false }
    /// )
    /// ```
    ///
    /// Exactly one of `onExit` / `onError` fires per session; `isPresented` is
    /// set back to `false` for you when the session ends.
    func meshpayLink(
        isPresented: Binding<Bool>,
        token: String,
        clientId: String,
        options: LinkOptions = LinkOptions(),
        onExit: @escaping (LinkExitSummary) -> Void,
        onError: @escaping (LinkError) -> Void
    ) -> some View {
        background(
            MeshpayLinkPresenter(
                isPresented: isPresented,
                token: token,
                clientId: clientId,
                options: options,
                onExit: onExit,
                onError: onError
            )
        )
    }
}

/// An invisible host whose coordinator owns the single ``LinkSession`` and
/// mirrors it to the `isPresented` binding.
private struct MeshpayLinkPresenter: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let token: String
    let clientId: String
    let options: LinkOptions
    let onExit: (LinkExitSummary) -> Void
    let onError: (LinkError) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ host: UIViewController, context: Context) {
        context.coordinator.parent = self
        context.coordinator.sync(isPresented: isPresented, host: host)
    }

    @MainActor
    final class Coordinator {
        var parent: MeshpayLinkPresenter
        private var session: LinkSession?
        private var presenting = false

        init(_ parent: MeshpayLinkPresenter) {
            self.parent = parent
        }

        func sync(isPresented: Bool, host: UIViewController) {
            if isPresented, !presenting {
                present(from: host)
            } else if !isPresented, presenting {
                session?.close()
            }
        }

        private func present(from host: UIViewController) {
            let session = LinkSession(
                token: parent.token,
                clientId: parent.clientId,
                options: parent.options,
                onExit: { [weak self] summary in
                    self?.finish()
                    self?.parent.onExit(summary)
                },
                onError: { [weak self] error in
                    self?.finish()
                    self?.parent.onError(error)
                }
            )
            self.session = session
            presenting = true
            // Present on the next runloop tick so a synchronous outcome — a blank
            // token/clientId reported through `onError` — never mutates SwiftUI
            // state during this view update.
            DispatchQueue.main.async { [weak self] in
                guard let self, self.session === session else {
                    return
                }
                session.present(from: host.topmostPresenter())
            }
        }

        private func finish() {
            presenting = false
            session = nil
            resetBinding()
        }

        private func resetBinding() {
            if parent.isPresented {
                parent.isPresented = false
            }
        }
    }
}

private extension UIViewController {
    /// The view controller actually on screen above `self`, so Link presents
    /// over any sheet the host has already put up.
    func topmostPresenter() -> UIViewController {
        var presenter: UIViewController = self
        while let presented = presenter.presentedViewController {
            presenter = presented
        }
        return presenter
    }
}
#endif
