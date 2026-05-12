import Foundation

public struct BankingAppState: Equatable {
    public var pendingRequest: ConsentRequest?
    public var issuedToken: OAuthToken?
    public var callbackURLToOpen: URL?
    public var isShowingFaceVerification = false
    public var isIssuingToken = false
    public var errorMessage: String?

    public init() {}
}

public enum BankingAppAction: Equatable {
    case handleIncomingURL(URL)
    case approveConsentTapped
    case faceVerificationCompleted(Bool)
    case tokenIssued(Result<OAuthToken, AppError>)
    case callbackOpened
    case declineConsent
    case setError(String?)
}

public struct BankingAppEnvironment {
    public let tokenIssuer: OAuthTokenIssuing

    public init(tokenIssuer: OAuthTokenIssuing) {
        self.tokenIssuer = tokenIssuer
    }

    public static let preview = BankingAppEnvironment(tokenIssuer: MockOAuthTokenIssuer())
}
