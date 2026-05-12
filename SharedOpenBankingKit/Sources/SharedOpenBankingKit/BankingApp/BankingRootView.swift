import SwiftUI

public struct HSBCBankingDemoRoot: View {
    @StateObject private var store: BankingAppStore

    public init(environment: BankingAppEnvironment = .preview) {
        _store = StateObject(wrappedValue: BankingAppStore(environment: environment))
    }

    public var body: some View {
        BankingRootView()
            .environmentObject(store)
    }
}

public struct BankingRootView: View {
    @EnvironmentObject private var store: BankingAppStore
    @Environment(\.openURL) private var openURL

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HSBCHeader()

                    if let request = store.state.pendingRequest {
                        ConsentReviewCard(request: request)
                    } else {
                        EmptyBankingState()
                    }

                    if let token = store.state.issuedToken {
                        TokenIssuedCard(token: token)
                    }
                }
                .padding(16)
            }
            .background(AppTheme.paper)
            .navigationTitle("HSBC")
            .toolbarTitleDisplayMode(.inline)
        }
        .onOpenURL { url in
            store.send(.handleIncomingURL(url))
        }
        .sheet(isPresented: Binding(
            get: { store.state.isShowingFaceVerification },
            set: { shown in
                if !shown {
                    store.send(.faceVerificationCompleted(false))
                }
            }
        )) {
            BankingFaceVerificationView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .alert("HSBC issue", isPresented: Binding(
            get: { store.state.errorMessage != nil },
            set: { _ in store.send(.setError(nil)) }
        )) {
            Button("OK", role: .cancel) { store.send(.setError(nil)) }
        } message: {
            Text(store.state.errorMessage ?? "")
        }
        .onChange(of: store.state.callbackURLToOpen) { _, url in
            guard let url else { return }
            openURL(url)
            store.send(.callbackOpened)
        }
    }
}

private struct HSBCHeader: View {
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(AppTheme.hsbcRed)
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "building.columns.fill")
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text("Mobile Banking")
                    .font(.headline)
                Text("Open Banking consent mock")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct EmptyBankingState: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "link.badge.plus")
                .font(.title)
                .foregroundStyle(AppTheme.hsbcRed)
            Text("Waiting for ChatGPT")
                .font(.headline)
            Text("Open this mock app from the ChatGPT-like app to review consent, verify face, and issue a mock OAuth token.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct ConsentReviewCard: View {
    @EnvironmentObject private var store: BankingAppStore
    let request: ConsentRequest

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("ChatGPT Coffee wants HSBC consent", systemImage: "checkmark.shield")
                .font(.headline)
                .foregroundStyle(AppTheme.ink)

            VStack(alignment: .leading, spacing: 7) {
                InfoRow(label: "Client", value: request.clientId)
                InfoRow(label: "Validity", value: "\(request.validityDays) days")
                InfoRow(label: "Merchants", value: request.merchantCategories.joined(separator: ", "))
            }

            VStack(alignment: .leading, spacing: 7) {
                Text("Scopes")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.muted)
                ForEach(request.scopes, id: \.rawValue) { scope in
                    Label(scope.rawValue, systemImage: "checkmark.circle")
                        .font(.subheadline)
                }
            }

            HStack(spacing: 10) {
                Button {
                    store.send(.approveConsentTapped)
                } label: {
                    Label("Authorize", systemImage: "faceid")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.hsbcRed)

                Button("Decline") {
                    store.send(.declineConsent)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.muted)
                .frame(width: 72, alignment: .leading)
            Text(value)
                .font(.subheadline)
            Spacer(minLength: 0)
        }
    }
}

private struct TokenIssuedCard: View {
    let token: OAuthToken

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("OAuth token issued", systemImage: "key.fill")
                .font(.headline)
                .foregroundStyle(.green)
            Text("Account ****\(token.accountMask)")
                .font(.subheadline)
            Text("Access token \(token.redactedAccessToken)")
                .font(.caption)
                .foregroundStyle(AppTheme.muted)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct BankingFaceVerificationView: View {
    @EnvironmentObject private var store: BankingAppStore

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "faceid")
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.hsbcRed)

            Text("Verify in HSBC")
                .font(.title3.weight(.semibold))

            Text("HSBC verifies the customer before granting consent and issuing the OAuth token.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppTheme.muted)

            Button {
                store.send(.faceVerificationCompleted(true))
            } label: {
                Label("Verify & Authorize", systemImage: "checkmark.shield")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.hsbcRed)

            Button("Cancel") {
                store.send(.faceVerificationCompleted(false))
            }
            .foregroundStyle(AppTheme.muted)
        }
        .padding(24)
    }
}
