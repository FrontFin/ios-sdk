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

    @Test func systemThemeFollowsDeviceNotHostOverride() {
        // A host that forces the opposite of the device appearance must not
        // change what `system` resolves to.
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let deviceIsDark = window.screen.traitCollection.userInterfaceStyle == .dark
        window.overrideUserInterfaceStyle = deviceIsDark ? .light : .dark
        #expect(window.traitCollection.userInterfaceStyle != window.screen.traitCollection.userInterfaceStyle)
        #expect(LinkSession.resolveIsDark(.system, in: window) == deviceIsDark)
    }

    @Test func explicitThemeIgnoresAppearance() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        window.overrideUserInterfaceStyle = .dark
        #expect(LinkSession.resolveIsDark(.light, in: window) == false)
        window.overrideUserInterfaceStyle = .light
        #expect(LinkSession.resolveIsDark(.dark, in: window) == true)
    }
}
#endif
