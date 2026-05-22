import Foundation

public enum Journey: String, Codable, Equatable {
    case hsbcConsent
    case wealth
    case coffeeOrder
}

public enum ConsentStatus: Equatable {
    case disconnected
    case pendingRedirect
    case authorizing
    case connected(OAuthToken)
    case failed(String)
}

public struct OAuthToken: Identifiable, Codable, Equatable {
    public let id: UUID
    public let accessToken: String
    public let refreshToken: String
    public let scopes: [HSBCScope]
    public let issuedAt: Date
    public let expiresAt: Date
    public let accountMask: String
    public let consentId: UUID

    public init(
        id: UUID = UUID(),
        accessToken: String,
        refreshToken: String,
        scopes: [HSBCScope],
        issuedAt: Date,
        expiresAt: Date,
        accountMask: String,
        consentId: UUID = UUID()
    ) {
        self.id = id
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.scopes = scopes
        self.issuedAt = issuedAt
        self.expiresAt = expiresAt
        self.accountMask = accountMask
        self.consentId = consentId
    }
}

public enum HSBCScope: String, Codable, CaseIterable, Equatable {
    case readAccounts = "accounts:read"
    case createPaymentQuote = "payment-quote:create"
    case authorizeDSPPayment = "dsp-payment:authorize"
    case submitCoffeePayment = "coffee-payment:submit"
    case submitTravelPayment = "travel-payment:submit"
}

public struct ConsentRequest: Identifiable, Codable, Equatable {
    public let id: UUID
    public let clientId: String
    public let redirectURL: URL
    public let callbackURL: URL
    public let scopes: [HSBCScope]
    public let merchantCategories: [String]
    public let validityDays: Int

    public init(
        id: UUID = UUID(),
        clientId: String,
        redirectURL: URL,
        callbackURL: URL,
        scopes: [HSBCScope],
        merchantCategories: [String],
        validityDays: Int
    ) {
        self.id = id
        self.clientId = clientId
        self.redirectURL = redirectURL
        self.callbackURL = callbackURL
        self.scopes = scopes
        self.merchantCategories = merchantCategories
        self.validityDays = validityDays
    }
}

public struct CoffeeShop: Identifiable, Codable, Equatable {
    public let id: UUID
    public let name: String
    public let distanceMeters: Int
    public let rating: Double
    public let estimatedPickupMinutes: Int
    public let brandColorHex: String
    public let menu: [CoffeeItem]

    public init(
        id: UUID = UUID(),
        name: String,
        distanceMeters: Int,
        rating: Double,
        estimatedPickupMinutes: Int,
        brandColorHex: String,
        menu: [CoffeeItem]
    ) {
        self.id = id
        self.name = name
        self.distanceMeters = distanceMeters
        self.rating = rating
        self.estimatedPickupMinutes = estimatedPickupMinutes
        self.brandColorHex = brandColorHex
        self.menu = menu
    }
}

public struct CoffeeItem: Identifiable, Codable, Equatable {
    public let id: UUID
    public let name: String
    public let detail: String
    public let price: Decimal
    public let currencyCode: String
    public let caffeineLevel: CaffeineLevel

    public init(
        id: UUID = UUID(),
        name: String,
        detail: String,
        price: Decimal,
        currencyCode: String,
        caffeineLevel: CaffeineLevel
    ) {
        self.id = id
        self.name = name
        self.detail = detail
        self.price = price
        self.currencyCode = currencyCode
        self.caffeineLevel = caffeineLevel
    }
}

public enum CaffeineLevel: String, Codable, Equatable {
    case low
    case medium
    case high
}

public struct CoffeeOrder: Identifiable, Codable, Equatable {
    public let id: UUID
    public let shop: CoffeeShop
    public let item: CoffeeItem
    public var size: CoffeeSize
    public var quantity: Int
    public var status: OrderStatus

    public init(
        id: UUID = UUID(),
        shop: CoffeeShop,
        item: CoffeeItem,
        size: CoffeeSize,
        quantity: Int,
        status: OrderStatus = .draft
    ) {
        self.id = id
        self.shop = shop
        self.item = item
        self.size = size
        self.quantity = quantity
        self.status = status
    }

    public var total: Decimal {
        item.price * Decimal(quantity)
    }
}

public enum CoffeeSize: String, Codable, CaseIterable, Equatable {
    case tall = "Tall"
    case grande = "Grande"
    case venti = "Venti"
}

public enum OrderStatus: String, Codable, Equatable {
    case draft
    case awaitingConfirmation
    case verifyingFace
    case paying
    case paid
    case failed
}

public struct PaymentReceipt: Identifiable, Codable, Equatable {
    public let id: UUID
    public let paymentReference: String
    public let orderId: UUID
    public let amount: Decimal
    public let currencyCode: String
    public let paidAt: Date
}

public struct PortfolioSummary: Identifiable, Codable, Equatable {
    public let id: UUID
    public let currencyCode: String
    public let totalValue: Decimal
    public let categories: [PortfolioCategory]

    public init(
        id: UUID = UUID(),
        currencyCode: String,
        totalValue: Decimal,
        categories: [PortfolioCategory]
    ) {
        self.id = id
        self.currencyCode = currencyCode
        self.totalValue = totalValue
        self.categories = categories
    }
}

public struct PortfolioCategory: Identifiable, Codable, Equatable {
    public let id: UUID
    public let name: String
    public let percentage: Double
    public let value: Decimal
    public let colorHex: String

    public init(
        id: UUID = UUID(),
        name: String,
        percentage: Double,
        value: Decimal,
        colorHex: String
    ) {
        self.id = id
        self.name = name
        self.percentage = percentage
        self.value = value
        self.colorHex = colorHex
    }
}

public struct TopFundsList: Identifiable, Codable, Equatable {
    public let id: UUID
    public let title: String
    public let funds: [TopFund]

    public init(
        id: UUID = UUID(),
        title: String,
        funds: [TopFund]
    ) {
        self.id = id
        self.title = title
        self.funds = funds
    }
}

public struct TopFund: Identifiable, Codable, Equatable {
    public let id: UUID
    public let name: String
    public let code: String
    public let badge: String?
    public let oneYearReturn: Double

    public init(
        id: UUID = UUID(),
        name: String,
        code: String,
        badge: String?,
        oneYearReturn: Double
    ) {
        self.id = id
        self.name = name
        self.code = code
        self.badge = badge
        self.oneYearReturn = oneYearReturn
    }
}

public struct DSPPaymentAuthorization: Identifiable, Codable, Equatable {
    public let id: UUID
    public let quoteId: UUID
    public let orderId: UUID
    public let decision: DSPAuthorizationDecision
    public let riskScore: Int
    public let authorizedAt: Date
    public let expiresAt: Date

    public init(
        id: UUID = UUID(),
        quoteId: UUID = UUID(),
        orderId: UUID,
        decision: DSPAuthorizationDecision,
        riskScore: Int,
        authorizedAt: Date = Date(),
        expiresAt: Date = Date().addingTimeInterval(180)
    ) {
        self.id = id
        self.quoteId = quoteId
        self.orderId = orderId
        self.decision = decision
        self.riskScore = riskScore
        self.authorizedAt = authorizedAt
        self.expiresAt = expiresAt
    }
}

public enum DSPAuthorizationDecision: String, Codable, Equatable {
    case approved
    case stepUpRequired
    case declined
}

public struct ChatMessage: Identifiable, Codable, Equatable {
    public let id: UUID
    public let role: ChatRole
    public let text: String
    public let createdAt: Date
    public let attachment: ChatAttachment?

    public init(
        id: UUID = UUID(),
        role: ChatRole,
        text: String,
        createdAt: Date = Date(),
        attachment: ChatAttachment? = nil
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.createdAt = createdAt
        self.attachment = attachment
    }
}

public enum ChatRole: String, Codable, Equatable {
    case user
    case assistant
    case system
}

public enum ChatAttachment: Codable, Equatable {
    case bindHSBCCard(ConsentRequest)
    case portfolioSummary(PortfolioSummary)
    case topFunds(TopFundsList)
    case shopCarousel([CoffeeShop])
    case orderCard(CoffeeOrder)
    case paymentReceipt(PaymentReceipt)
}

public struct ConsentApproval: Codable, Equatable {
    public let request: ConsentRequest
    public let accountMask: String
    public let approvedAt: Date

    public init(request: ConsentRequest, accountMask: String, approvedAt: Date = Date()) {
        self.request = request
        self.accountMask = accountMask
        self.approvedAt = approvedAt
    }
}
