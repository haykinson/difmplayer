import SwiftUI
import AppKit

public struct LoginSheet: View {
    @ObservedObject public var viewModel: AppViewModel
    @ObservedObject private var auth = AuthManager.shared
    public let onClose: () -> Void

    @State private var selectedTab: Int = 0 // 0: Listen Key, 1: Email/Password
    @State private var inputListenKey: String = ""
    @State private var usernameInput: String = ""
    @State private var passwordInput: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil

    public init(viewModel: AppViewModel, onClose: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "key.fill")
                        .foregroundColor(Color(red: 0.12, green: 0.84, blue: 0.38))
                    Text("DI.FM Premium Authentication")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 22)
            .padding(.top, 20)
            .padding(.bottom, 16)
            .background(Color(red: 0.12, green: 0.12, blue: 0.14))

            Divider().background(Color.white.opacity(0.08))

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Status Banner
                    if auth.isAuthenticated {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Color(red: 0.12, green: 0.84, blue: 0.38))

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Premium Account Active")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)

                                if !auth.username.isEmpty {
                                    Text("Logged in as \(auth.username)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.7))
                                } else {
                                    Text("Listen Key: ••••••••\(String(auth.listenKey.suffix(4)))")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }

                            Spacer()

                            Button(action: {
                                auth.logout()
                                successMessage = nil
                                errorMessage = nil
                            }) {
                                Text("Log Out")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.red.opacity(0.9))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.red.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(red: 0.12, green: 0.84, blue: 0.38).opacity(0.3), lineWidth: 1)
                        )
                    }

                    // Quality Selector Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("STREAM AUDIO QUALITY")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.4))

                        Picker("", selection: $auth.selectedQuality) {
                            ForEach(AudioQuality.allCases) { q in
                                Text(q.displayName).tag(q)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    // Tab Switcher: Listen Key vs Username/Password
                    Picker("", selection: $selectedTab) {
                        Text("Listen Key (Instant)").tag(0)
                        Text("Account Login").tag(1)
                    }
                    .pickerStyle(.segmented)

                    if selectedTab == 0 {
                        // LISTEN KEY TAB
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Your DI.FM Listen Key is your unique token that unlocks high-quality 320k streams in external players without needing your password.")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.65))
                                .fixedSize(horizontal: false, vertical: true)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Listen Key")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.85))

                                HStack {
                                    TextField("Enter or paste your Listen Key...", text: $inputListenKey)
                                        .textFieldStyle(.plain)
                                        .font(.system(size: 13, design: .monospaced))
                                        .foregroundColor(.white)

                                    if !inputListenKey.isEmpty {
                                        Button(action: { inputListenKey = "" }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.white.opacity(0.4))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(10)
                                .background(Color.white.opacity(0.07))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }

                            HStack {
                                Button(action: {
                                    guard let url = URL(string: "https://www.di.fm/settings") else { return }
                                    NSWorkspace.shared.open(url)
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "safari")
                                        Text("Find Listen Key on DI.FM Settings")
                                    }
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(red: 0.12, green: 0.84, blue: 0.38))
                                }
                                .buttonStyle(.plain)

                                Spacer()

                                Button(action: {
                                    let key = inputListenKey.trimmingCharacters(in: .whitespacesAndNewlines)
                                    if !key.isEmpty {
                                        viewModel.auth.setListenKeyDirectly(key)
                                        successMessage = "Listen Key saved successfully!"
                                        errorMessage = nil
                                    } else {
                                        errorMessage = "Please enter a valid Listen Key."
                                    }
                                }) {
                                    Text("Save Listen Key")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color(red: 0.12, green: 0.84, blue: 0.38))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } else {
                        // USERNAME / PASSWORD TAB
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Sign in with your AudioAddict / DI.FM credentials to automatically retrieve and store your Listen Key.")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.65))

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Email or Username")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.85))

                                TextField("your_email@example.com", text: $usernameInput)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 13))
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color.white.opacity(0.07))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Password")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.85))

                                SecureField("••••••••••••", text: $passwordInput)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 13))
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color.white.opacity(0.07))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }

                            HStack {
                                Spacer()

                                Button(action: loginWithCredentials) {
                                    HStack(spacing: 8) {
                                        if isLoading {
                                            ProgressView().scaleEffect(0.7).colorInvert()
                                        }
                                        Text(isLoading ? "Signing in..." : "Log In")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.black)
                                    }
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 8)
                                    .background(Color(red: 0.12, green: 0.84, blue: 0.38))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                                .disabled(isLoading || usernameInput.isEmpty || passwordInput.isEmpty)
                            }
                        }
                    }

                    // Alerts
                    if let err = errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(err)
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                        }
                        .padding(10)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    if let succ = successMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(red: 0.12, green: 0.84, blue: 0.38))
                            Text(succ)
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 0.12, green: 0.84, blue: 0.38))
                        }
                        .padding(10)
                        .background(Color(red: 0.12, green: 0.84, blue: 0.38).opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(22)
            }
        }
        .frame(width: 480, height: 490)
        .background(Color(red: 0.08, green: 0.08, blue: 0.10))
        .onAppear {
            inputListenKey = viewModel.auth.listenKey
            usernameInput = viewModel.auth.username
        }
    }

    private func loginWithCredentials() {
        isLoading = true
        errorMessage = nil
        successMessage = nil

        Task {
            do {
                let res = try await AudioAddictAPI.shared.authenticate(
                    network: viewModel.currentNetwork,
                    username: usernameInput,
                    password: passwordInput
                )
                if let key = res.listenKey {
                    viewModel.auth.listenKey = key
                    viewModel.auth.username = usernameInput
                    self.successMessage = "Successfully logged in to \(viewModel.currentNetwork.name) Premium!"
                    self.isLoading = false
                }
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}
