import MeshpayLink
import SwiftUI

/// A minimal tester for MeshPay Link: paste a client ID and a session token
/// (minted on your backend — never ship the client secret in an app), optionally
/// pick a language and environment, and open Link.
struct ContentView: View {
    @State private var clientId = ""
    @State private var token = ""
    @State private var language = ""
    @State private var displayFiatCurrency = ""
    @State private var integrationId = ""
    @State private var environment: LinkEnvironment = .prod
    @State private var theme: LinkTheme?

    @State private var showLink = false
    @State private var lastResult: String?

    private var canOpen: Bool {
        !clientId.trimmingCharacters(in: .whitespaces).isEmpty
            && !token.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Credentials") {
                    ClearableField(title: "Client ID", text: $clientId)
                    ClearableField(title: "Session token", text: $token)
                }

                Section("Options") {
                    Picker("Environment", selection: $environment) {
                        Text("Sandbox").tag(LinkEnvironment.sbx)
                        Text("Production").tag(LinkEnvironment.prod)
                        Text("Dev").tag(LinkEnvironment.dev)
                    }
                    Picker("Theme", selection: $theme) {
                        Text("Not set").tag(LinkTheme?.none)
                        Text("System").tag(LinkTheme?.some(.system))
                        Text("Light").tag(LinkTheme?.some(.light))
                        Text("Dark").tag(LinkTheme?.some(.dark))
                    }
                    ClearableField(title: "Language (e.g. en, es)", text: $language)
                    ClearableField(title: "Display fiat currency (e.g. USD, DKK)", text: $displayFiatCurrency)
                    ClearableField(title: "Integration ID (e.g. metamask)", text: $integrationId)
                }

                if let lastResult {
                    Section("Link result") {
                        Text(lastResult).font(.footnote).foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button {
                        showLink = true
                    } label: {
                        Text("Open Link")
                            .fontWeight(.semibold)
                            .foregroundColor(.meshYellow)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .disabled(!canOpen)
                }
            }
            .navigationTitle("MeshPay Link")
            .meshpayLink(
                isPresented: $showLink,
                token: token,
                clientId: clientId,
                options: LinkOptions(
                    environment: environment,
                    language: language.isEmpty ? nil : language,
                    theme: theme,
                    integrationId: integrationId.isEmpty ? nil : integrationId,
                    displayFiatCurrency: displayFiatCurrency.isEmpty ? nil : displayFiatCurrency
                ),
                onExit: { summary in
                    lastResult = "Exit: \(summary.status == .success ? "success" : "canceled")"
                },
                onError: { error in
                    lastResult = "Error: \(error.code.rawValue) — \(error.message)"
                }
            )
        }
        // Single-column stack on every device (iOS 15's NavigationView otherwise
        // shows a split layout on iPad).
        .navigationViewStyle(.stack)
    }
}

extension Color {
    /// Mesh brand ("wordmark") yellow — `#F8FF4D`.
    static let meshYellow = Color(red: 0xF8 / 255, green: 0xFF / 255, blue: 0x4D / 255)
}

/// A text field with a trailing "✕" button that clears it while it has content.
private struct ClearableField: View {
    let title: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack {
            TextField(title, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(keyboardType)
                .tint(.meshYellow)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.meshYellow.opacity(0.7))
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Clear \(title)")
            }
        }
    }
}

#Preview {
    ContentView()
}
