import Foundation

public enum AppAction: Equatable {
    case sendMessage(String)
    case startHSBCBinding
    case consentRequestCreated(ConsentRequest)
    case openHSBCAppRequested
    case hsbcAppReturned(Result<OAuthToken, AppError>)
    case handleIncomingURL(URL)
    case showPortfolio
    case showTopFunds
    case startCoffeeJourney
    case shopsLoaded([CoffeeShop])
    case selectShop(CoffeeShop)
    case selectCoffee(CoffeeItem)
    case updateSize(CoffeeSize)
    case updateQuantity(Int)
    case createOrder
    case confirmPayment
    case faceVerificationCompleted(Bool)
    case paymentCompleted(Result<PaymentReceipt, AppError>)
    case dismissFaceVerification
    case setError(String?)
}

public enum AppError: Error, Equatable {
    case consentDeclined
    case missingConsent
    case missingOrder
    case biometricFailed
    case paymentDeclined
    case serviceUnavailable

    public var message: String {
        switch self {
        case .consentDeclined:
            return "HSBC consent was declined."
        case .missingConsent:
            return "Please bind HSBC before paying."
        case .missingOrder:
            return "No order is ready to pay."
        case .biometricFailed:
            return "Face verification failed."
        case .paymentDeclined:
            return "HSBC declined this payment."
        case .serviceUnavailable:
            return "Service is temporarily unavailable."
        }
    }
}
