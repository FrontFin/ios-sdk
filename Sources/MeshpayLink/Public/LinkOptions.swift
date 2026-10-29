import Foundation

/// Which hosted Link deployment to open.
public enum LinkEnvironment: String, Sendable, Equatable {
    case dev
    case prod
    case sbx
}

/// Link's colour theme. `system` is resolved from the device appearance when
/// Link opens; Link itself is always told `light` or `dark`.
public enum LinkTheme: String, Sendable, Equatable {
    case light
    case dark
    case system
}

/// Optional Link settings. Every field is optional; the defaults open prod on
/// Link's configured start screen, following the device appearance.
public struct LinkOptions: Sendable, Equatable {
    /// Which Link deployment to open. Defaults to `prod`.
    public var environment: LinkEnvironment
    /// UI language as a locale code (e.g. `"es"`, `"pt-BR"`), passed to Link as
    /// `lng`.
    public var language: String?
    /// `system` is resolved from the device appearance when Link opens.
    public var theme: LinkTheme?
    /// Which screen Link opens on. Serialised to Link as JSON, never validated
    /// here.
    public var flow: LinkFlowConfig?
    /// Pre-select a wallet integration so Link opens straight to its connect
    /// step.
    public var integrationId: String?
    /// ISO 4217 code (e.g. `"DKK"`) for the currency Link shows and quotes
    /// amounts in. A hint; Link validates it.
    public var displayFiatCurrency: String?
    /// Advanced / testing only: load Link from a LocalCan tunnel
    /// (`https://*.localcan.dev`). Any other value is ignored in favour of the
    /// environment default. Never wire this to untrusted input.
    public var linkUrl: String?

    public init(
        environment: LinkEnvironment = .prod,
        language: String? = nil,
        theme: LinkTheme? = nil,
        flow: LinkFlowConfig? = nil,
        integrationId: String? = nil,
        displayFiatCurrency: String? = nil,
        linkUrl: String? = nil
    ) {
        self.environment = environment
        self.language = language
        self.theme = theme
        self.flow = flow
        self.integrationId = integrationId
        self.displayFiatCurrency = displayFiatCurrency
        self.linkUrl = linkUrl
    }
}
