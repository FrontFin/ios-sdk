import Foundation
import Testing

@testable import MeshpayLink

@Suite("LinkFlowConfig JSON")
struct LinkFlowConfigTests {
    @Test func encodesEachFlowInWebKeyOrder() {
        #expect(LinkFlowConfig.fiatOnRamp.encodedJSON() == "{\"flow\":\"fiatOnRamp\"}")
        #expect(LinkFlowConfig.fiatOffRamp.encodedJSON() == "{\"flow\":\"fiatOffRamp\"}")
        #expect(LinkFlowConfig.login(entry: .catalog).encodedJSON() == "{\"flow\":\"login\",\"entry\":{\"type\":\"catalog\"}}")
        #expect(
            LinkFlowConfig.login(entry: .depositHome(showBuyOption: true)).encodedJSON()
                == "{\"flow\":\"login\",\"entry\":{\"type\":\"deposit-home\",\"showBuyOption\":true}}"
        )
        #expect(
            LinkFlowConfig.login(entry: .depositHomeIntegrations()).encodedJSON()
                == "{\"flow\":\"login\",\"entry\":{\"type\":\"deposit-home-integrations\"}}"
        )
        #expect(
            LinkFlowConfig.enterAmount(depositHomeDrawer: true, showBuyOption: false).encodedJSON()
                == "{\"flow\":\"enter-amount\",\"depositHomeDrawer\":true,\"showBuyOption\":false}"
        )
        #expect(LinkFlowConfig.enterAmount().encodedJSON() == "{\"flow\":\"enter-amount\"}")
    }

    @Test func decodesTheWebShape() throws {
        #expect(try decode("{\"flow\":\"fiatOnRamp\"}") == .fiatOnRamp)
        #expect(try decode("{\"flow\":\"login\",\"entry\":{\"type\":\"catalog\"}}") == .login(entry: .catalog))
        #expect(
            try decode("{\"flow\":\"login\",\"entry\":{\"type\":\"deposit-home\",\"showBuyOption\":true}}")
                == .login(entry: .depositHome(showBuyOption: true))
        )
        #expect(
            try decode("{\"flow\":\"enter-amount\",\"depositHomeDrawer\":true}")
                == .enterAmount(depositHomeDrawer: true, showBuyOption: nil)
        )
    }

    private func decode(_ json: String) throws -> LinkFlowConfig {
        try JSONDecoder().decode(LinkFlowConfig.self, from: Data(json.utf8))
    }
}
