import Foundation

/// Decides when the native loader and close button show around Link. Pure
/// state, so the timing rules are unit-tested without a WebView; the view
/// controller feeds it events and mirrors the two flags onto its views.
///
/// - Loader: appears after ``Constants/loaderDelay`` unless Link's own page has
///   committed (it then draws its own loading state) or Link reported `loaded`.
/// - Close button: appears after ``Constants/closeButtonDelay`` until Link
///   reports `loaded` (Link draws its own close). After that it shows only on a
///   foreign page or a failed navigation, so the user always has a way out.
struct LoadingChrome: Equatable {
    private(set) var isLoaderVisible = false
    private(set) var isCloseButtonVisible = false
    /// Link reported `loaded` over the bridge.
    private(set) var isLoaded = false

    private var isLinkPageCommitted = false
    private var isNavigationFailed = false
    private var isEnded = false

    mutating func loaderDelayElapsed() {
        if !isEnded, !isLoaded, !isLinkPageCommitted {
            isLoaderVisible = true
        }
    }

    mutating func closeButtonDelayElapsed() {
        if !isEnded, !isLoaded {
            isCloseButtonVisible = true
        }
    }

    /// A new top-frame navigation started; it replaces any failed document.
    mutating func navigationStarted() {
        isNavigationFailed = false
    }

    /// A top-frame page committed. `onLinkOrigin` is false for a foreign page,
    /// an error page or no URL.
    mutating func pageCommitted(onLinkOrigin: Bool) {
        if onLinkOrigin {
            isLinkPageCommitted = true
            isLoaderVisible = false
        }
        updateCloseButtonAfterLoad(onLinkOrigin: onLinkOrigin)
    }

    mutating func pageFinished(onLinkOrigin: Bool) {
        updateCloseButtonAfterLoad(onLinkOrigin: onLinkOrigin)
    }

    mutating func linkLoaded() {
        isLoaded = true
        isNavigationFailed = false
        isLoaderVisible = false
        isCloseButtonVisible = false
    }

    /// A navigation failed after Link loaded: keep the session, offer a way out.
    mutating func navigationFailedAfterLoad() {
        isNavigationFailed = true
        isCloseButtonVisible = true
    }

    /// The session delivered its outcome; nothing appears from now on.
    mutating func ended() {
        isEnded = true
        isLoaderVisible = false
    }

    private mutating func updateCloseButtonAfterLoad(onLinkOrigin: Bool) {
        if isLoaded {
            isCloseButtonVisible = isNavigationFailed || !onLinkOrigin
        }
    }
}
