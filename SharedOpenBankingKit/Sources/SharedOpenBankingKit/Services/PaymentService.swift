import Foundation

public protocol PaymentServicing {
    func pay(order: CoffeeOrder, token: OAuthToken) async throws -> PaymentReceipt
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
