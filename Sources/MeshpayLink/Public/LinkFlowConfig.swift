import Foundation

/// Which screen Link opens on.
///
/// Mirrors `flow-config.ts` in `FrontFin/web-sdk`, so the web and mobile SDKs
/// accept the same `flow` shape. The SDK passes `flow` straight through to the
/// Link UI as a query parameter and never inspects or validates it.
///
/// It serialises to exactly the same JSON the web SDK produces (``encodedJSON``):
/// the `flow` discriminator first, then its options.
public enum LinkFlowConfig: Sendable, Equatable {
    /// Where the `login` flow enters.
    public enum LoginEntry: Sendable, Equatable {
        case catalog
        case depositHome(showBuyOption: Bool? = nil)
        case depositHomeIntegrations(showBuyOption: Bool? = nil)
    }

    /// The catalog / deposit-home login flow.
    case login(entry: LoginEntry)
    /// The enter-amount flow. `depositHomeDrawer` renders a deposit-home-style
    /// "Pay with" drawer; `showBuyOption` adds "Buy crypto" to it and is only
    /// honoured when the drawer is on.
    case enterAmount(depositHomeDrawer: Bool? = nil, showBuyOption: Bool? = nil)
    /// Fiat on-ramp ("Buy") flow. Self-contained, no sub-config.
    case fiatOnRamp
    /// Fiat off-ramp ("Sell") flow. Self-contained, no sub-config.
    case fiatOffRamp
}

extension LinkFlowConfig {
    /// The exact JSON the web SDK produces for this flow, with keys in web order:
    /// `flow` first, then its options. Built by hand (not `JSONEncoder`) because
    /// the hosted contract and the shared URL vectors depend on key order.
    func encodedJSON() -> String {
        switch self {
        case .fiatOnRamp:
            return "{\"flow\":\"fiatOnRamp\"}"
        case .fiatOffRamp:
            return "{\"flow\":\"fiatOffRamp\"}"
        case let .login(entry):
            return "{\"flow\":\"login\",\"entry\":\(entry.encodedJSON())}"
        case let .enterAmount(depositHomeDrawer, showBuyOption):
            var json = "{\"flow\":\"enter-amount\""
            if let depositHomeDrawer {
                json += ",\"depositHomeDrawer\":\(depositHomeDrawer ? "true" : "false")"
            }
            if let showBuyOption {
                json += ",\"showBuyOption\":\(showBuyOption ? "true" : "false")"
            }
            json += "}"
            return json
        }
    }
}

extension LinkFlowConfig.LoginEntry {
    func encodedJSON() -> String {
        switch self {
        case .catalog:
            return "{\"type\":\"catalog\"}"
        case let .depositHome(showBuyOption):
            return Self.entryJSON(type: "deposit-home", showBuyOption: showBuyOption)
        case let .depositHomeIntegrations(showBuyOption):
            return Self.entryJSON(type: "deposit-home-integrations", showBuyOption: showBuyOption)
        }
    }

    private static func entryJSON(type: String, showBuyOption: Bool?) -> String {
        var json = "{\"type\":\"\(type)\""
        if let showBuyOption {
            json += ",\"showBuyOption\":\(showBuyOption ? "true" : "false")"
        }
        json += "}"
        return json
    }
}

// MARK: - Decoding (from the shared web JSON shape)

extension LinkFlowConfig: Decodable {
    private enum CodingKeys: String, CodingKey {
        case flow
        case entry
        case depositHomeDrawer
        case showBuyOption
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let flow = try container.decode(String.self, forKey: .flow)
        switch flow {
        case "login":
            let entry = try container.decode(LoginEntry.self, forKey: .entry)
            self = .login(entry: entry)
        case "enter-amount":
            let depositHomeDrawer = try container.decodeIfPresent(Bool.self, forKey: .depositHomeDrawer)
            let showBuyOption = try container.decodeIfPresent(Bool.self, forKey: .showBuyOption)
            self = .enterAmount(depositHomeDrawer: depositHomeDrawer, showBuyOption: showBuyOption)
        case "fiatOnRamp":
            self = .fiatOnRamp
        case "fiatOffRamp":
            self = .fiatOffRamp
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .flow,
                in: container,
                debugDescription: "Unknown flow \"\(flow)\""
            )
        }
    }
}

extension LinkFlowConfig.LoginEntry: Decodable {
    private enum CodingKeys: String, CodingKey {
        case type
        case showBuyOption
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        let showBuyOption = try container.decodeIfPresent(Bool.self, forKey: .showBuyOption)
        switch type {
        case "catalog":
            self = .catalog
        case "deposit-home":
            self = .depositHome(showBuyOption: showBuyOption)
        case "deposit-home-integrations":
            self = .depositHomeIntegrations(showBuyOption: showBuyOption)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown login entry \"\(type)\""
            )
        }
    }
}
