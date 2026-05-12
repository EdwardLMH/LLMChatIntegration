import Foundation

public enum AppScheme {
    public static let chatGPT = "chatgpt"
    public static let hsbcMobile = "hsbc-mobile"
}

public enum AppURLRoute: Equatable {
    case hsbcConsent(ConsentRequest)
    case chatConsentCallback(Result<OAuthToken, AppError>)
    case unknown
}

public enum AppURLRouter {
    public static func route(_ url: URL) -> AppURLRoute {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return .unknown
        }

        if components.scheme == AppScheme.hsbcMobile,
           components.host == "open-banking",
           normalizedPath(components.path) == "/consent" {
            guard let request = ConsentRequest(urlComponents: components) else { return .unknown }
            return .hsbcConsent(request)
        }

        if components.scheme == AppScheme.chatGPT,
           components.host == "hsbc",
           normalizedPath(components.path) == "/consent-callback" {
            if queryValue("status", in: components) == "declined" {
                return .chatConsentCallback(.failure(.consentDeclined))
            }
            guard let token = OAuthToken(callbackComponents: components) else { return .unknown }
            return .chatConsentCallback(.success(token))
        }

        return .unknown
    }

    private static func normalizedPath(_ path: String) -> String {
        path.hasPrefix("/") ? path : "/" + path
    }

    static func queryValue(_ name: String, in components: URLComponents) -> String? {
        components.queryItems?.first(where: { $0.name == name })?.value
    }
}

public extension ConsentRequest {
    var hsbcDeepLinkURL: URL {
        var components = URLComponents()
        components.scheme = AppScheme.hsbcMobile
        components.host = "open-banking"
        components.path = "/consent"
        components.queryItems = [
            URLQueryItem(name: "request_id", value: id.uuidString),
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "callback_url", value: callbackURL.absoluteString),
            URLQueryItem(name: "scopes", value: scopes.map(\.rawValue).joined(separator: ",")),
            URLQueryItem(name: "merchant_categories", value: merchantCategories.joined(separator: ",")),
            URLQueryItem(name: "validity_days", value: String(validityDays))
        ]
        return components.url!
    }

    init?(urlComponents components: URLComponents) {
        guard
            let requestId = AppURLRouter.queryValue("request_id", in: components),
            let id = UUID(uuidString: requestId),
            let clientId = AppURLRouter.queryValue("client_id", in: components),
            let callbackURLString = AppURLRouter.queryValue("callback_url", in: components),
            let callbackURL = URL(string: callbackURLString),
            let scopesValue = AppURLRouter.queryValue("scopes", in: components),
            let validityValue = AppURLRouter.queryValue("validity_days", in: components),
            let validityDays = Int(validityValue)
        else {
            return nil
        }

        let scopes = scopesValue
            .split(separator: ",")
            .compactMap { HSBCScope(rawValue: String($0)) }

        guard !scopes.isEmpty else { return nil }

        self.init(
            id: id,
            clientId: clientId,
            redirectURL: components.url ?? URL(string: "hsbc-mobile://open-banking/consent")!,
            callbackURL: callbackURL,
            scopes: scopes,
            merchantCategories: AppURLRouter.queryValue("merchant_categories", in: components)?
                .split(separator: ",")
                .map(String.init) ?? [],
            validityDays: validityDays
        )
    }
}

public extension OAuthToken {
    var redactedAccessToken: String {
        "..." + accessToken.suffix(8)
    }

    init?(callbackComponents components: URLComponents) {
        guard
            let accessToken = AppURLRouter.queryValue("access_token", in: components),
            let refreshToken = AppURLRouter.queryValue("refresh_token", in: components),
            let accountMask = AppURLRouter.queryValue("account_mask", in: components),
            let scopesValue = AppURLRouter.queryValue("scopes", in: components),
            let expiresAtValue = AppURLRouter.queryValue("expires_at", in: components),
            let expiresAtSeconds = TimeInterval(expiresAtValue),
            let consentIdValue = AppURLRouter.queryValue("consent_id", in: components),
            let consentId = UUID(uuidString: consentIdValue)
        else {
            return nil
        }

        let scopes = scopesValue
            .split(separator: ",")
            .compactMap { HSBCScope(rawValue: String($0)) }

        guard !scopes.isEmpty else { return nil }

        self.init(
            accessToken: accessToken,
            refreshToken: refreshToken,
            scopes: scopes,
            issuedAt: Date(),
            expiresAt: Date(timeIntervalSince1970: expiresAtSeconds),
            accountMask: accountMask,
            consentId: consentId
        )
    }

    func callbackURL(baseURL: URL) -> URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "status", value: "approved"),
            URLQueryItem(name: "access_token", value: accessToken),
            URLQueryItem(name: "refresh_token", value: refreshToken),
            URLQueryItem(name: "account_mask", value: accountMask),
            URLQueryItem(name: "scopes", value: scopes.map(\.rawValue).joined(separator: ",")),
            URLQueryItem(name: "expires_at", value: String(Int(expiresAt.timeIntervalSince1970))),
            URLQueryItem(name: "consent_id", value: consentId.uuidString)
        ]
        return components.url!
    }
}
