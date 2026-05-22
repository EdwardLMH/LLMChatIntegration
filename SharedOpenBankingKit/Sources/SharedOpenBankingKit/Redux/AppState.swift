import Foundation

public struct AppState: Equatable {
    public var consentStatus: ConsentStatus = .disconnected
    public var consentRequest: ConsentRequest?
    public var hsbcDeepLinkToOpen: URL?
    public var selectedJourney: Journey = .hsbcConsent
    public var messages: [ChatMessage] = [
        ChatMessage(role: .assistant, text: "Welcome to the ChatGPTCoffee x HSBC shopping experience. You can bind your HSBC account here, discover nearby offers, and place orders in conversation, while HSBC provides secure account consent, facial verification, and payment protection when you are ready to check out.")
    ]
    public var shops: [CoffeeShop] = []
    public var selectedShop: CoffeeShop?
    public var selectedItem: CoffeeItem?
    public var currentOrder: CoffeeOrder?
    public var receipt: PaymentReceipt?
    public var isShowingFaceVerification = false
    public var isLoading = false
    public var errorMessage: String?

    public init() {}
}
