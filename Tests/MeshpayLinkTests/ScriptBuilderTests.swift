import Testing

@testable import MeshpayLink

@Suite("Injected scripts")
struct ScriptBuilderTests {
    @Test func announcesPlatformAndVersionAtDocumentStart() {
        #expect(
            ScriptBuilder.documentStartScript(version: "1.2.3")
                == "window.meshSdkPlatform = \"iOS\";window.meshSdkVersion = \"1.2.3\";true;"
        )
    }

    @Test func jsonEncodesTheVersionInsteadOfConcatenatingIt() {
        #expect(
            ScriptBuilder.documentStartScript(version: "1'; alert(1); '")
                .contains("window.meshSdkVersion = \"1'; alert(1); '\";")
        )
    }

    @Test func postsTheSdkSpecsHandshake() {
        #expect(
            ScriptBuilder.sdkSpecsScript(version: "1.2.3")
                == "window.postMessage({\"type\":\"meshSDKSpecs\",\"payload\":{\"platform\":\"iOS\",\"version\":\"1.2.3\"}}, '*');true;"
        )
    }

    @Test func postsCloseRequested() {
        #expect(ScriptBuilder.closeRequestedScript() == "window.postMessage({\"type\":\"closeRequested\"}, '*');true;")
    }

    @Test func escapesControlCharactersInJSONStrings() {
        #expect(ScriptBuilder.jsonString("a\nb\t\"c\\") == "\"a\\nb\\t\\\"c\\\\\"")
    }
}
