#if canImport(UIKit)
import UIKit
import WebKit

/// The outcome a session produces. Exactly one is delivered, exactly once
/// (solution design §2.3).
enum LinkOutcome {
    case exit(LinkExitStatus)
    case error(LinkError)
}

/// Hosts the `WKWebView` that shows Link full screen, speaks the bridge, routes
/// external navigations to the OS, and drives the single-outcome lifecycle.
@MainActor
final class LinkViewController: UIViewController {
    private let scriptHandlerName = "jsMessageHandler"

    private let built: LinkURLBuilder.Built
    private let isDark: Bool
    private let onOutcome: (LinkOutcome) -> Void

    private var webView: WKWebView?
    private var closeButton: CloseButton?
    private var loader: LoaderView?

    private var done = false
    private var closing = false
    private var loaded = false
    private var navigationFailed = false

    private var loadWork: DispatchWorkItem?
    private var graceWork: DispatchWorkItem?
    private var closeButtonWork: DispatchWorkItem?
    private var loaderWork: DispatchWorkItem?

    init(built: LinkURLBuilder.Built, isDark: Bool, onOutcome: @escaping (LinkOutcome) -> Void) {
        self.built = built
        self.isDark = isDark
        self.onOutcome = onOutcome
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        isDark ? .lightContent : .darkContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ThemeColor.background(isDark: isDark)

        guard let url = URL(string: built.href) else {
            // href is form-encoded and well-formed; this is unreachable.
            finish(.error(LinkError(code: .loadError, message: "The Link URL could not be built.")))
            return
        }

        let webView = makeWebView()
        self.webView = webView
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        addLoader()
        addCloseButton()

        startLoadTimer()
        startLoaderTimer()
        startCloseButtonTimer()
        webView.load(URLRequest(url: url))
    }

    /// The host dismissed Link, or something below it (logout swapping the UI, a
    /// deep link resetting it, the sheet holding `.meshLink` closing), without
    /// going through ``finish(_:)``. End the session so exactly one outcome is
    /// still delivered and the single-use token can't be presented again.
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        guard !done else {
            return
        }
        if isBeingDismissed || presentingViewController == nil {
            finish(.exit(.canceled))
            return
        }
        // Still presented: Link is covered by something full screen (a camera
        // picker, a host screen). A dismissal lower in the stack may not flag this
        // controller as being dismissed, so re-check once UIKit has settled.
        // `self` is captured strongly so the controller survives until then.
        DispatchQueue.main.async { [self] in
            if !done, presentingViewController == nil {
                finish(.exit(.canceled))
            }
        }
    }

    // MARK: - WebView

    private func makeWebView() -> WKWebView {
        let controller = WKUserContentController()
        controller.addUserScript(
            WKUserScript(
                source: ScriptBuilder.documentStartScript(version: SDKVersion.current),
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            )
        )
        controller.add(WeakScriptMessageHandler(self), name: scriptHandlerName)

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = controller
        // Link needs no persistent storage or cookies across sessions (§7 Q2),
        // and the token must never be persisted (§2.7).
        configuration.websiteDataStore = .nonPersistent()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        // Required for the gestureless `window.open` some on-ramps use.
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = false
        webView.scrollView.bounces = false
        webView.backgroundColor = ThemeColor.background(isDark: isDark)
        webView.isOpaque = false
        #if DEBUG
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        #endif
        return webView
    }

    // MARK: - Loader

    private func addLoader() {
        let loader = LoaderView(tint: ThemeColor.foreground(isDark: isDark))
        loader.translatesAutoresizingMaskIntoConstraints = false
        loader.isHidden = true
        view.addSubview(loader)
        NSLayoutConstraint.activate([
            loader.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loader.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        self.loader = loader
    }

    // MARK: - Close button

    private func addCloseButton() {
        let button = CloseButton(tint: ThemeColor.foreground(isDark: isDark))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        button.isHidden = true
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            button.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16)
        ])
        closeButton = button
    }

    private func setCloseButton(visible: Bool) {
        closeButton?.isHidden = !visible
        if visible {
            closeButton.map { view.bringSubviewToFront($0) }
        }
    }

    @objc private func closeButtonTapped() {
        requestClose()
    }

    // MARK: - Host-initiated close

    /// Asks Link to close gracefully; tears down when Link answers with `close`
    /// or after ``Constants/closeGrace``, whichever comes first.
    func requestClose() {
        guard !done, !closing, webView != nil else {
            return
        }
        closing = true
        // The host asked to close, so a slow load must not turn it into an error.
        cancel(&loadWork)
        webView?.evaluateJavaScript(ScriptBuilder.closeRequestedScript(), completionHandler: nil)
        graceWork = schedule(after: Constants.closeGrace) { [weak self] in
            self?.finish(.exit(.canceled))
        }
    }

    // MARK: - Timers

    private func startLoadTimer() {
        loadWork = schedule(after: Constants.loadTimeout) { [weak self] in
            guard let self, !self.closing else { return }
            self.finish(.error(LinkError(
                code: .loadTimeout,
                message: "Link did not load within \(Int(Constants.loadTimeout)) seconds."
            )))
        }
    }

    private func startLoaderTimer() {
        loaderWork = schedule(after: Constants.loaderDelay) { [weak self] in
            guard let self, !self.loaded else { return }
            self.loader?.isHidden = false
        }
    }

    private func startCloseButtonTimer() {
        closeButtonWork = schedule(after: Constants.closeButtonDelay) { [weak self] in
            guard let self, !self.loaded else { return }
            self.setCloseButton(visible: true)
        }
    }

    private func schedule(after seconds: TimeInterval, _ block: @escaping () -> Void) -> DispatchWorkItem {
        let work = DispatchWorkItem(block: block)
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: work)
        return work
    }

    private func cancel(_ work: inout DispatchWorkItem?) {
        work?.cancel()
        work = nil
    }

    // MARK: - Outcome

    /// Before Link has loaded, a failed page means Link could not be shown. After
    /// that, a failed navigation must not discard a session the user may be
    /// halfway through: surface the native close button instead.
    private func handleLoadFailure() {
        if loaded, !closing {
            navigationFailed = true
            setCloseButton(visible: true)
        } else {
            fail(.loadError, "The Link page failed to load.")
        }
    }

    /// Once the host has asked to close, it was promised `onExit`; a WebView that
    /// fails during the grace period can no longer answer, so end it as canceled.
    private func fail(_ code: LinkErrorCode, _ message: String) {
        finish(closing ? .exit(.canceled) : .error(LinkError(code: code, message: message)))
    }

    private func finish(_ outcome: LinkOutcome) {
        guard !done else {
            return
        }
        done = true
        cancel(&loadWork)
        cancel(&graceWork)
        cancel(&closeButtonWork)
        cancel(&loaderWork)
        loader?.isHidden = true
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: scriptHandlerName)
        webView?.navigationDelegate = nil
        webView?.uiDelegate = nil
        onOutcome(outcome)
    }

    // MARK: - Origin check

    private func isFromLink(_ frame: WKFrameInfo) -> Bool {
        frame.isMainFrame && originString(frame.securityOrigin) == built.origin
    }

    private func originString(_ origin: WKSecurityOrigin) -> String {
        let scheme = origin.protocol.lowercased()
        let host = origin.host.lowercased()
        let defaultPort = scheme == "https" ? 443 : scheme == "http" ? 80 : -1
        if origin.port == 0 || origin.port == defaultPort {
            return "\(scheme)://\(host)"
        }
        return "\(scheme)://\(host):\(origin.port)"
    }

    private func updateCloseButtonForCurrentPage() {
        guard loaded else {
            return
        }
        var currentOrigin: String?
        if let urlString = webView?.url?.absoluteString {
            currentOrigin = URLOrigin.origin(of: urlString)
        }
        setCloseButton(visible: navigationFailed || currentOrigin != built.origin)
    }
}

// MARK: - WKScriptMessageHandler

extension LinkViewController: WKScriptMessageHandler {
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard !done, message.name == scriptHandlerName, isFromLink(message.frameInfo) else {
            return
        }
        switch BridgeMessage.parse(message.body) {
        case let .close(status):
            finish(.exit(status))
        case .loaded:
            cancel(&loadWork)
            cancel(&closeButtonWork)
            cancel(&loaderWork)
            loaded = true
            navigationFailed = false
            setCloseButton(visible: false)
            loader?.isHidden = true
            webView?.evaluateJavaScript(ScriptBuilder.sdkSpecsScript(version: SDKVersion.current), completionHandler: nil)
        case nil:
            break
        }
    }
}

// MARK: - WKNavigationDelegate

extension LinkViewController: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction
    ) async -> WKNavigationActionPolicy {
        guard let url = navigationAction.request.url?.absoluteString else {
            return .cancel
        }
        let isMainFrame = navigationAction.targetFrame?.isMainFrame ?? true
        switch NavigationPolicy.decideNavigation(url: url, isMainFrame: isMainFrame, linkOrigin: built.origin) {
        case .load:
            return .allow
        case .block:
            return .cancel
        case let .openExternal(externalURL, fallbackURL):
            openExternally(externalURL, fallbackURL: fallbackURL)
            return .cancel
        }
    }

    /// An HTTP error on the main document is a completed navigation to WebKit,
    /// not a `didFail`, so it would otherwise end the load guard and show an
    /// error page. Treat it as a load failure, matching `onHttpError` on React
    /// Native. Cancelling surfaces as a policy-change error, which
    /// `isCancellation` ignores.
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse
    ) async -> WKNavigationResponsePolicy {
        guard navigationResponse.isForMainFrame,
              let response = navigationResponse.response as? HTTPURLResponse,
              response.statusCode >= 400
        else {
            return .allow
        }
        handleLoadFailure()
        return .cancel
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        // A new top-frame navigation replaces any failed document.
        navigationFailed = false
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        // Link's page has started drawing, so it takes over from the native
        // spinner. An error page or a foreign page does not count.
        if let urlString = webView.url?.absoluteString,
           URLOrigin.origin(of: urlString) == built.origin {
            cancel(&loaderWork)
            loader?.isHidden = true
        }
        updateCloseButtonForCurrentPage()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        cancel(&loadWork)
        updateCloseButtonForCurrentPage()
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: any Error
    ) {
        guard !isCancellation(error) else {
            return
        }
        handleLoadFailure()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
        guard !isCancellation(error) else {
            return
        }
        handleLoadFailure()
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        // The token is single-use, so the session cannot be resumed by reloading.
        fail(.sessionInterrupted, "The Link WebView stopped and the session cannot resume.")
    }

    /// `.cancel` from the navigation policy, and redirects WebKit reports as
    /// cancellations, are not load failures.
    private func isCancellation(_ error: any Error) -> Bool {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCancelled {
            return true
        }
        // WebKitErrorDomain, "frame load interrupted by policy change".
        return nsError.domain == "WebKitErrorDomain" && nsError.code == 102
    }
}

// MARK: - WKUIDelegate

extension LinkViewController: WKUIDelegate {
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if let url = navigationAction.request.url?.absoluteString,
           case let .openExternal(externalURL, fallbackURL) = NavigationPolicy.decideNewWindow(url: url) {
            openExternally(externalURL, fallbackURL: fallbackURL)
        }
        // A new window never opens inside the SDK.
        return nil
    }

    /// Hand a URL to the OS — the wallet app for a custom scheme, the app or
    /// browser for `https`. `UIApplication.open` issues a view intent, so unlike
    /// `canOpenURL` it is not gated on the `LSApplicationQueriesSchemes` list.
    /// `SFSafariViewController` is deliberately not used: it never triggers the
    /// universal links that return the user to a wallet app.
    private func openExternally(_ urlString: String, fallbackURL: String?) {
        guard let url = URL(string: urlString) else {
            openFallback(fallbackURL)
            return
        }
        UIApplication.shared.open(url, options: [:]) { [weak self] opened in
            if !opened {
                self?.openFallback(fallbackURL)
            }
        }
    }

    private func openFallback(_ fallbackURL: String?) {
        guard let fallbackURL, let url = URL(string: fallbackURL) else {
            return
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

/// Weakly forwards script messages so the content controller does not retain the
/// view controller (the classic `WKUserContentController` → VC leak).
private final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var target: (any WKScriptMessageHandler)?

    init(_ target: any WKScriptMessageHandler) {
        self.target = target
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        target?.userContentController(userContentController, didReceive: message)
    }
}
#endif
