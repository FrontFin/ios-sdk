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

    /// The view carrying `.meshpayLink` was removed: no update with
    /// `isPresented == false` will follow, so end the session here.
    static func dismantleUIViewController(_ host: UIViewController, coordinator: Coordinator) {
        coordinator.end()
    }

    @MainActor
    final class Coordinator {
        var parent: MeshpayLinkPresenter
        private var session: LinkSession?
        private var presenting = false
        /// Created but not yet presented: `present` is deferred a runloop tick.
        private var pending = false

        init(_ parent: MeshpayLinkPresenter) {
            self.parent = parent
        }

        func sync(isPresented: Bool, host: UIViewController) {
            if isPresented, !presenting {
                present(from: host)
            } else if !isPresented, presenting {
                end()
            }
        }

        /// Closes the active session, or cancels one still waiting to present
        /// (`close()` would be a no-op: it has no controller yet).
        func end() {
            guard presenting else {
                return
            }
            if pending {
                cancelPending()
            } else {
                session?.close()
            }
        }

        private func present(from host: UIViewController) {
            // The callbacks hold the coordinator strongly so they still reach the
            // integrator after the view is dismantled; `finish` breaks the cycle.
            let session = LinkSession(
                token: parent.token,
                clientId: parent.clientId,
                options: parent.options,
                onExit: { summary in
                    self.finish()
                    self.parent.onExit(summary)
                },
                onError: { error in
                    self.finish()
                    self.parent.onError(error)
                }
            )
            self.session = session
            presenting = true
            pending = true
            // Present on the next runloop tick so a synchronous outcome — a blank
            // token/clientId reported through `onError` — never mutates SwiftUI
            // state during this view update.
            DispatchQueue.main.async { [weak self] in
                guard let self, self.session === session else {
                    return
                }
                guard self.parent.isPresented else {
                    self.cancelPending()
                    return
                }
                self.pending = false
                session.present(from: host.topmostPresenter())
            }
        }

        /// Drops a session that never opened and reports it as canceled, so the
        /// integrator still gets exactly one outcome. Deferred, because this can
        /// run during a SwiftUI view update.
        private func cancelPending() {
            clear()
            DispatchQueue.main.async {
                self.resetBinding()
                self.parent.onExit(LinkExitSummary(status: .canceled))
            }
        }

        private func finish() {
            clear()
            resetBinding()
        }

        private func clear() {
            presenting = false
            pending = false
            session = nil
        }

        private func resetBinding() {
            if parent.isPresented {
                parent.isPresented = false
            }
        }
    }
}
#endif
