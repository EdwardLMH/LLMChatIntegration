import Foundation

public protocol ConsentServicing {
    func createConsentRequest() async throws -> ConsentRequest
}

public struct MockConsentService: ConsentServicing {
    private let clientId = "chatgpt-coffee"

    public init() {}

    public func createConsentRequest() async throws -> ConsentRequest {
        let draft = ConsentRequest(
            clientId: clientId,
            redirectURL: URL(string: "hsbc-mobile://open-banking/consent")!,
            callbackURL: URL(string: "chatgpt://hsbc/consent-callback")!,
            scopes: [.readAccounts, .createPaymentQuote, .submitCoffeePayment],
            merchantCategories: ["coffee", "food-and-beverage"],
            validityDays: 30
        )
        return ConsentRequest(
            id: draft.id,
            clientId: draft.clientId,
            redirectURL: draft.hsbcDeepLinkURL,
            callbackURL: draft.callbackURL,
            scopes: draft.scopes,
            merchantCategories: draft.merchantCategories,
            validityDays: draft.validityDays
        )
    }
}

public protocol OAuthTokenIssuing {
    func issueToken(for approval: ConsentApproval) async throws -> OAuthToken
}

public struct MockOAuthTokenIssuer: OAuthTokenIssuing {
    public init() {}

    public func issueToken(for approval: ConsentApproval) async throws -> OAuthToken {
        ConsentCallbackParser.tokenFromSuccessfulCallback(
            accountMask: approval.accountMask,
            scopes: approval.request.scopes,
            consentId: approval.request.id
        )
    }
}

public enum ConsentCallbackParser {
    public static func tokenFromSuccessfulCallback(
        accountMask: String = "1234",
        scopes: [HSBCScope] = [.readAccounts, .createPaymentQuote, .submitCoffeePayment],
        consentId: UUID = UUID()
    ) -> OAuthToken {
        OAuthToken(
            accessToken: "mock-access-token-issued-by-hsbc",
            refreshToken: "mock-refresh-token-issued-by-hsbc",
            scopes: scopes,
            issuedAt: Date(),
            expiresAt: Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date(),
            accountMask: accountMask,
            consentId: consentId
        )
    }
}
