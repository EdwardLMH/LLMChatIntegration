import Foundation
import SwiftUI

@MainActor
public final class BankingAppStore: ObservableObject {
    @Published public private(set) var state: BankingAppState

    private let environment: BankingAppEnvironment

    public init(initialState: BankingAppState = BankingAppState(), environment: BankingAppEnvironment = .preview) {
        self.state = initialState
        self.environment = environment
    }

    public func send(_ action: BankingAppAction) {
        reduce(action)
    }

    private func reduce(_ action: BankingAppAction) {
        switch action {
        case let .handleIncomingURL(url):
            switch AppURLRouter.route(url) {
            case let .hsbcConsent(request):
                state.pendingRequest = request
                state.issuedToken = nil
                state.callbackURLToOpen = nil
            default:
                state.errorMessage = "Unsupported HSBC app link."
            }

        case .approveConsentTapped:
            guard state.pendingRequest != nil else {
                state.errorMessage = "No consent request is waiting."
                return
            }
            state.isShowingFaceVerification = true

        case let .faceVerificationCompleted(success):
            state.isShowingFaceVerification = false
            guard success else {
                state.errorMessage = AppError.biometricFailed.message
                return
            }
            guard let request = state.pendingRequest else { return }
            state.isIssuingToken = true
            Task { await issueToken(for: request) }

        case let .tokenIssued(result):
            state.isIssuingToken = false
            switch result {
            case let .success(token):
                state.issuedToken = token
                state.callbackURLToOpen = token.callbackURL(baseURL: tokenCallbackBaseURL)
            case let .failure(error):
                state.errorMessage = error.message
            }

        case .callbackOpened:
            state.callbackURLToOpen = nil

        case .declineConsent:
            guard let request = state.pendingRequest else { return }
            state.callbackURLToOpen = declinedCallbackURL(baseURL: request.callbackURL)
            state.pendingRequest = nil

        case let .setError(message):
            state.errorMessage = message
        }
    }

    private var tokenCallbackBaseURL: URL {
        state.pendingRequest?.callbackURL ?? URL(string: "chatgpt://hsbc/consent-callback")!
    }

    private func issueToken(for request: ConsentRequest) async {
        do {
            let approval = ConsentApproval(request: request, accountMask: "1234")
            let token = try await environment.tokenIssuer.issueToken(for: approval)
            reduce(.tokenIssued(.success(token)))
        } catch {
            reduce(.tokenIssued(.failure(.serviceUnavailable)))
        }
    }

    private func declinedCallbackURL(baseURL: URL) -> URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "status", value: "declined")]
        return components.url!
    }
}
