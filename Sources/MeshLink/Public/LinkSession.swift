#if canImport(UIKit)
import UIKit

/// One Mesh Link session.
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
/// You don't need to keep a reference to the session: Link keeps it alive while
/// it is on screen. Keep one only to call ``close()``.
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
    /// Set once Link is handed to UIKit. `controller` is weak, so it alone can't
    /// stop a second `present` from reusing the single-use token.
    private var started = false

    /// - Parameters:
    ///   - token: Session token from `POST /v2/sessions`, minted by your backend.
    ///   - clientId: Your Mesh client ID.
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
    /// opened or finished; a session is presented at most once.
    ///
    /// A blank `token` or `clientId` (empty or whitespace only) is reported once
    /// through `onError` with ``LinkErrorCode/loadError`` and nothing opens.
    public func present(from presenter: UIViewController, animated: Bool = true) {
        guard !finished, !started else {
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

        // Present over whatever is already on screen; presenting straight from
        // `presenter` would be a silent no-op if it is already presenting.
        let target = presenter.topmostPresenter()
        // A presenter that isn't in a window can't present. Without this, `present`
        // is a no-op, UIKit never retains the controller (``controller`` is weak),
        // and neither callback would ever fire — so report it instead.
        guard let window = target.viewIfLoaded?.window else {
            deliver(.error(LinkError(code: .loadError, message: "Link could not be presented.")))
            return
        }

        guard let controller = makeController(token: trimmedToken, clientId: trimmedClientId, in: window) else {
            // Unreachable: the blanks are handled above.
            deliver(.error(LinkError(code: .loadError, message: "The Link URL could not be built.")))
            return
        }
        controller.modalPresentationStyle = .fullScreen
        controller.modalPresentationCapturesStatusBarAppearance = true
        self.controller = controller
        started = true
        target.present(controller, animated: animated)

        // `presentingViewController` is set synchronously on a successful present;
        // if it is still nil the presentation was dropped (e.g. mid-transition), so
        // guarantee the single outcome rather than leaving the session wedged.
        if controller.presentingViewController == nil {
            deliver(.error(LinkError(code: .loadError, message: "Link could not be presented.")))
        }
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
        // Skip when the host is already dismissing Link (it reported through
        // `viewDidDisappear`): a second dismiss mid-transition only adds warnings.
        if let presented, !presented.isBeingDismissed, presented.presentingViewController != nil {
            // Dismiss from Link's presenter: on Link itself, `dismiss` only closes
            // whatever Link is presenting (a host alert, a file or camera picker)
            // and leaves Link on screen. From the presenter, it removes Link and
            // everything above it.
            if let presenter = presented.presentingViewController,
               presenter.presentedViewController === presented {
                presenter.dismiss(animated: true)
            } else {
                presented.dismiss(animated: true)
            }
        }
        switch outcome {
        case let .exit(status):
            onExit(LinkExitSummary(status: status))
        case let .error(error):
            onError(error)
        }
    }

    /// Builds Link's controller with the theme resolved against `window`'s
    /// device appearance. Nil only if the URL can't be built.
    func makeController(token: String, clientId: String, in window: UIWindow) -> LinkViewController? {
        let deviceIsDark = Self.deviceIsDark(in: window)
        guard let built = try? LinkURLBuilder.build(
            token: token,
            clientId: clientId,
            options: options,
            isDarkAppearance: deviceIsDark
        ) else {
            return nil
        }
        let isDark = LinkURLBuilder.resolvesDark(options.theme ?? .system, isDarkAppearance: deviceIsDark)
        // Captured strongly on purpose: the presented controller keeps the session
        // alive, so an integrator need not store it. No cycle — `controller` is weak.
        return LinkViewController(built: built, isDark: isDark) { outcome in
            self.deliver(outcome)
        }
    }

    /// The device appearance, not the host app's: a host override — UIKit's
    /// `overrideUserInterfaceStyle` or SwiftUI's `.preferredColorScheme`, which
    /// lands on the window scene — flows into the presenter's, window's and
    /// scene's traits, so only the screen's traits still report the device
    /// setting.
    static func deviceIsDark(in window: UIWindow) -> Bool {
        window.screen.traitCollection.userInterfaceStyle == .dark
    }
}
#endif
