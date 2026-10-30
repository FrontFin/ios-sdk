import MeshpayLink
import SwiftUI

/// A minimal tester for MeshPay Link: paste a client ID and a session token
/// (minted on your backend — never ship the client secret in an app), optionally
/// pick a language and environment, and open Link.
struct ContentView: View {
    @State private var clientId = ""
    @State private var token = ""
    @State private var language = ""
    @State private var environment: LinkEnvironment = .sbx
    @State private var theme: LinkTheme = .system

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
                    TextField("Client ID", text: $clientId)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Session token", text: $token)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Options") {
                    Picker("Environment", selection: $environment) {
                        Text("Sandbox").tag(LinkEnvironment.sbx)
                        Text("Production").tag(LinkEnvironment.prod)
                        Text("Dev").tag(LinkEnvironment.dev)
                    }
                    Picker("Theme", selection: $theme) {
                        Text("System").tag(LinkTheme.system)
                        Text("Light").tag(LinkTheme.light)
                        Text("Dark").tag(LinkTheme.dark)
                    }
                    TextField("Language (e.g. en, es)", text: $language)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                if let lastResult {
                    Section("Last session") {
                        Text(lastResult).font(.footnote).foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button("Open Link") { showLink = true }
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
                    theme: theme
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

#Preview {
    ContentView()
}
