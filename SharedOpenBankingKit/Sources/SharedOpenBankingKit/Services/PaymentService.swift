import Foundation

public protocol PaymentServicing {
    func pay(order: CoffeeOrder, token: OAuthToken) async throws -> PaymentReceipt
}

public protocol DSPAuthorizationServicing {
    func authorizePayment(order: CoffeeOrder, token: OAuthToken, biometricAssertion: String) async throws -> DSPPaymentAuthorization
}

public struct MockDSPAuthorizationService: DSPAuthorizationServicing {
    public init() {}

    public func authorizePayment(order: CoffeeOrder, token: OAuthToken, biometricAssertion: String) async throws -> DSPPaymentAuthorization {
        guard token.scopes.contains(.authorizeDSPPayment) else {
            throw AppError.missingConsent
        }
        guard !biometricAssertion.isEmpty else {
            throw AppError.biometricFailed
        }

        return DSPPaymentAuthorization(
            orderId: order.id,
            decision: .approved,
            riskScore: 18
        )
    }
}

public struct MockPaymentService: PaymentServicing {
    public init() {}

    public func pay(order: CoffeeOrder, token: OAuthToken) async throws -> PaymentReceipt {
        guard token.scopes.contains(.submitCoffeePayment) else {
            throw AppError.missingConsent
        }

        return PaymentReceipt(
            id: UUID(),
            paymentReference: "HSBC-\(Int.random(in: 100_000...999_999))",
            orderId: order.id,
            amount: order.total,
            currencyCode: order.item.currencyCode,
            paidAt: Date()
        )
    }
}
