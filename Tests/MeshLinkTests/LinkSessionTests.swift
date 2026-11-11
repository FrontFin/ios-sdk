#if canImport(UIKit)
import UIKit
import Testing

@testable import MeshLink

@Suite("LinkSession configuration")
@MainActor
struct LinkSessionTests {
    @Test func reportsBlankTokenThroughOnError() {
        var captured: LinkError?
        let session = LinkSession(token: "   ", clientId: "c", onExit: { _ in }, onError: { captured = $0 })
        session.present(from: UIViewController())
        #expect(captured?.code == .loadError)
        #expect(captured?.message == "token is required.")
    }

    @Test func reportsBlankClientIdThroughOnError() {
        var captured: LinkError?
        let session = LinkSession(token: "t", clientId: "   ", onExit: { _ in }, onError: { captured = $0 })
        session.present(from: UIViewController())
        #expect(captured?.code == .loadError)
        #expect(captured?.message == "clientId is required.")
    }

    @Test func doesNotReportForValidValuesBeforePresenting() {
        // Creating the session performs no validation and fires no callback;
        // a blank value is only reported when the session is presented.
        var errored = false
        _ = LinkSession(token: " t ", clientId: " c ", onExit: { _ in }, onError: { _ in errored = true })
        #expect(!errored)
    }

    @Test func reportsLoadErrorWhenPresenterCannotPresent() {
        // A presenter that is not in a window can't present; the session must
        // still deliver exactly one outcome rather than silently doing nothing.
        var captured: LinkError?
        let session = LinkSession(token: "t", clientId: "c", onExit: { _ in }, onError: { captured = $0 })
        session.present(from: UIViewController())
        #expect(captured?.code == .loadError)
        #expect(captured?.message == "Link could not be presented.")
    }

    /// A window whose app-level appearance is forced to the opposite of the
    /// device's, like a host using `overrideUserInterfaceStyle`.
    private func overriddenWindow() -> (window: UIWindow, deviceIsDark: Bool) {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let deviceIsDark = window.screen.traitCollection.userInterfaceStyle == .dark
        window.overrideUserInterfaceStyle = deviceIsDark ? .light : .dark
        return (window, deviceIsDark)
    }

    @Test(arguments: [LinkTheme.system, nil])
    func systemThemeFollowsDeviceNotHostOverride(_ theme: LinkTheme?) throws {
        let (window, deviceIsDark) = overriddenWindow()
        #expect(window.traitCollection.userInterfaceStyle != window.screen.traitCollection.userInterfaceStyle)

        let session = LinkSession(token: "t", clientId: "c", options: LinkOptions(theme: theme), onExit: { _ in }, onError: { _ in })
        let controller = try #require(session.makeController(token: "t", clientId: "c", in: window))

        // Both the native chrome and the URL follow the device.
        #expect(controller.isDark == deviceIsDark)
        let expectedTh = theme == nil ? nil : (deviceIsDark ? "th=dark" : "th=light")
        #expect(controller.built.href.contains("th=") == (expectedTh != nil))
        if let expectedTh {
            #expect(controller.built.href.contains(expectedTh))
        }
    }

    @Test(arguments: [LinkTheme.light, .dark])
    func explicitThemeWinsOverDevice(_ theme: LinkTheme) throws {
        let (window, _) = overriddenWindow()
        let session = LinkSession(token: "t", clientId: "c", options: LinkOptions(theme: theme), onExit: { _ in }, onError: { _ in })
        let controller = try #require(session.makeController(token: "t", clientId: "c", in: window))
        #expect(controller.isDark == (theme == .dark))
        #expect(controller.built.href.contains("th=\(theme.rawValue)"))
    }
}
#endif
