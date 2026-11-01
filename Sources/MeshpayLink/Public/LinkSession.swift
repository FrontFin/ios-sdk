#if canImport(UIKit)
import UIKit

/// One MeshPay Link session.
///
/// Mint a session token on **your backend** (never ship your client secret in
/// the app), create a `LinkSession`, then present it:
///
/// ```swift
/// let session = LinkSession(
///     token: sessionToken,
///     clientId: clientId,
///     options: LinkOptions(environment: .prod, theme: .system, language: "en"),
///     onExit: { summary in /* summary.status: .success | .canceled */ },
///     onError: { error in print(error.code) }
/// )
/// session.present(from: viewController)
/// ```
///
/// Exactly one of `onExit` / `onError` is called per session, exactly once, on
/// the main actor. After it fires the session is finished and cannot reopen.
///
/// A blank `token` or `clientId` is **not** an error you have to catch: the
/// session reports it through `onError` with ``LinkErrorCode/loadError`` when you
/// present it, and nothing opens.
@MainActor
public final class LinkSession {
    private let token: String
    private let clientId: String
    private let options: LinkOptions
    private let onExit: (LinkExitSummary) -> Void
    private let onError: (LinkError) -> Void

    private weak var controller: LinkViewController?
    private var finished = false

    /// - Parameters:
    ///   - token: Session token from `POST /v2/sessions`, minted by your backend.
    ///   - clientId: Your MeshPay client ID.
    ///   - options: Optional Link settings.
    ///   - onExit: Called once when the session ends normally.
    ///   - onError: Called once when Link can't be shown or can't continue —
    ///     including when `token` or `clientId` is blank (``LinkErrorCode/loadError``).
    public init(
        token: String,
        clientId: String,
        options: LinkOptions = LinkOptions(),
        onExit: @escaping (LinkExitSummary) -> Void,
        onError: @escaping (LinkError) -> Void
    ) {
        self.token = token
        self.clientId = clientId
        self.options = options
        self.onExit = onExit
        self.onError = onError
    }

    /// Present Link full screen from `presenter`. A no-op once the session has
    /// opened or finished.
    ///
    /// A blank `token` or `clientId` (empty or whitespace only) is reported once
    /// through `onError` with ``LinkErrorCode/loadError`` and nothing opens.
    public func present(from presenter: UIViewController, animated: Bool = true) {
        guard !finished, controller == nil else {
            return
        }

        let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedToken.isEmpty else {
            deliver(.error(LinkError(code: .loadError, message: "token is required.")))
            return
        }
        let trimmedClientId = clientId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedClientId.isEmpty else {
            deliver(.error(LinkError(code: .loadError, message: "clientId is required.")))
            return
        }

        let isDark: Bool
        switch options.theme ?? .system {
        case .dark:
            isDark = true
        case .light:
            isDark = false
        case .system:
            isDark = presenter.traitCollection.userInterfaceStyle == .dark
        }

        guard let built = try? LinkURLBuilder.build(
            token: trimmedToken,
            clientId: trimmedClientId,
            options: options,
            isDarkAppearance: isDark
        ) else {
            // Unreachable: the blanks are handled above.
            deliver(.error(LinkError(code: .loadError, message: "The Link URL could not be built.")))
            return
        }

        let controller = LinkViewController(built: built, isDark: isDark) { [weak self] outcome in
            self?.deliver(outcome)
        }
        controller.modalPresentationStyle = .fullScreen
        controller.modalPresentationCapturesStatusBarAppearance = true
        self.controller = controller
        presenter.present(controller, animated: animated)
    }

    /// Close the active session: asks Link to close gracefully, waits up to one
    /// second for its status, then calls `onExit`. Same as dismissing from the
    /// native close button.
    public func close() {
        controller?.requestClose()
    }

    private func deliver(_ outcome: LinkOutcome) {
        guard !finished else {
            return
        }
        finished = true
        let presented = controller
        controller = nil
        presented?.dismiss(animated: true)
        switch outcome {
        case let .exit(status):
            onExit(LinkExitSummary(status: status))
        case let .error(error):
            onError(error)
        }
    }
}
#endif
