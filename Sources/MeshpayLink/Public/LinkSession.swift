#if canImport(UIKit)
import UIKit

/// One MeshPay Link session.
///
/// Mint a session token on **your backend** (never ship your client secret in
/// the app), create a `LinkSession`, then present it:
///
/// ```swift
/// let session = try LinkSession(
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
    /// - Throws: ``LinkConfigurationError/blankToken`` or
    ///   ``LinkConfigurationError/blankClientId`` when either is empty or
    ///   whitespace only, so a misconfigured integration fails at call time.
    public init(
        token: String,
        clientId: String,
        options: LinkOptions = LinkOptions(),
        onExit: @escaping (LinkExitSummary) -> Void,
        onError: @escaping (LinkError) -> Void
    ) throws {
        let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedToken.isEmpty else {
            throw LinkConfigurationError.blankToken
        }
        let trimmedClientId = clientId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedClientId.isEmpty else {
            throw LinkConfigurationError.blankClientId
        }
        self.token = trimmedToken
        self.clientId = trimmedClientId
        self.options = options
        self.onExit = onExit
        self.onError = onError
    }

    /// Present Link full screen from `presenter`. A no-op once the session has
    /// opened or finished.
    public func present(from presenter: UIViewController, animated: Bool = true) {
        guard !finished, controller == nil else {
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
            token: token,
            clientId: clientId,
            options: options,
            isDarkAppearance: isDark
        ) else {
            // Unreachable: token and clientId were validated at init.
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
