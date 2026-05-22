import Foundation
import SwiftUI

@MainActor
public final class AppStore: ObservableObject {
    @Published public private(set) var state: AppState

    private let environment: AppEnvironment

    public init(initialState: AppState, environment: AppEnvironment) {
        self.state = initialState
        self.environment = environment
    }

    public func send(_ action: AppAction) {
        reduce(action)
    }

    private func reduce(_ action: AppAction) {
        objectWillChange.send()

        switch action {
        case let .sendMessage(text):
            appendUser(text)
            routeUserMessage(text)

        case .startHSBCBinding:
            state.selectedJourney = .hsbcConsent
            state.isLoading = true
            appendAssistant("I will open HSBC Mobile Banking so you can authorize consent with facial recognition.")
            Task { await createConsentRequest() }

        case let .consentRequestCreated(request):
            state.isLoading = false
            state.consentRequest = request
            state.consentStatus = .pendingRedirect
            appendAssistant(
                "Please bind HSBC to continue. You will review scopes in HSBC Mobile Banking.",
                attachment: .bindHSBCCard(request)
            )

        case .openHSBCAppRequested:
            guard let request = state.consentRequest else { return }
            state.hsbcDeepLinkToOpen = request.redirectURL
            state.consentStatus = .authorizing
            appendAssistant("Opening HSBC Mobile Banking for face verification and consent approval.")

        case let .handleIncomingURL(url):
            switch AppURLRouter.route(url) {
            case let .chatConsentCallback(result):
                reduce(.hsbcAppReturned(result))
            default:
                break
            }

        case let .hsbcAppReturned(result):
            state.isLoading = false
            state.hsbcDeepLinkToOpen = nil
            switch result {
            case let .success(token):
                state.consentStatus = .connected(token)
                appendAssistant("HSBC is connected. Consent \(token.consentId.uuidString.prefix(8)) is active. You can ask about your portfolio, top funds, or continue to coffee when you are ready.")
            case let .failure(error):
                state.consentStatus = .failed(error.message)
                state.errorMessage = error.message
            }

        case .showPortfolio:
            guard case .connected = state.consentStatus else {
                appendAssistant("Please bind HSBC first, then I can show your portfolio.")
                return
            }
            state.selectedJourney = .wealth
            appendAssistant(
                "Sure. Here is your HSBC portfolio summary.",
                attachment: .portfolioSummary(SeedData.portfolioSummary)
            )

        case .showTopFunds:
            guard case .connected = state.consentStatus else {
                appendAssistant("Please bind HSBC first, then I can show top funds.")
                return
            }
            state.selectedJourney = .wealth
            appendAssistant(
                "Here are the top 3 funds for you.",
                attachment: .topFunds(SeedData.topFunds)
            )

        case .startCoffeeJourney:
            state.selectedJourney = .coffeeOrder
            state.isLoading = true
            appendAssistant("You sound like you need something warm. I am checking nearby coffee options and the weather.")
            Task { await loadCoffeeShops() }

        case let .shopsLoaded(shops):
            state.isLoading = false
            state.shops = shops
            appendAssistant("It is cool and cloudy nearby, so a latte might fit nicely. Here are nearby coffee shops.", attachment: .shopCarousel(shops))

        case let .selectShop(shop):
            let alreadySelected = state.selectedShop?.id == shop.id
            state.selectedShop = shop
            if !alreadySelected || state.selectedItem == nil {
                state.selectedItem = shop.menu.first
            }
            appendAssistant("\(shop.name) can have your order ready in about \(shop.estimatedPickupMinutes) minutes.")

        case let .selectCoffee(item):
            state.selectedItem = item

        case let .updateSize(size):
            state.currentOrder?.size = size

        case let .updateQuantity(quantity):
            state.currentOrder?.quantity = max(1, quantity)

        case .createOrder:
            guard let shop = state.selectedShop, let item = state.selectedItem else { return }
            let order = CoffeeOrder(shop: shop, item: item, size: .grande, quantity: 1, status: .awaitingConfirmation)
            state.currentOrder = order
            appendAssistant("Your order is ready. Since the weather is a bit grey, this should be a decent small rescue.", attachment: .orderCard(order))
            appendAssistant("Please confirm in chat or tap Pay when you are ready.")

        case .confirmPayment:
            guard case .connected = state.consentStatus else {
                state.errorMessage = AppError.missingConsent.message
                appendAssistant("Please bind HSBC first, then I can continue with payment.")
                return
            }
            guard var order = state.currentOrder else {
                state.errorMessage = AppError.missingOrder.message
                return
            }
            order.status = .verifyingFace
            state.currentOrder = order
            state.isShowingFaceVerification = true

        case let .faceVerificationCompleted(success):
            state.isShowingFaceVerification = false
            guard success else {
                state.errorMessage = AppError.biometricFailed.message
                appendAssistant(AppError.biometricFailed.message)
                return
            }
            guard let order = state.currentOrder, case let .connected(token) = state.consentStatus else { return }
            state.isLoading = true
            appendAssistant("Facial verification passed. I am calling HSBC DSP Authorization Agent through MCP to authorize this payment.")
            Task { await authorizeAndPay(order: order, token: token) }

        case let .paymentCompleted(result):
            state.isLoading = false
            switch result {
            case let .success(receipt):
                state.receipt = receipt
                state.currentOrder?.status = .paid
                appendAssistant("Paid with HSBC. Your coffee order is confirmed.", attachment: .paymentReceipt(receipt))
            case let .failure(error):
                state.currentOrder?.status = .failed
                state.errorMessage = error.message
                appendAssistant(error.message)
            }

        case .dismissFaceVerification:
            state.isShowingFaceVerification = false

        case let .setError(message):
            state.errorMessage = message
        }
    }

    private func routeUserMessage(_ text: String) {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if normalized.contains("bind") || normalized.contains("connect hsbc") || normalized.contains("use hsbc") {
            reduce(.startHSBCBinding)
        } else if normalized.contains("portfolio") || normalized.contains("profollio") || normalized.contains("portfollio") {
            reduce(.showPortfolio)
        } else if normalized.contains("top fund") || normalized.contains("top funds") || normalized.contains("top 3 fund") || normalized.contains("fund list") {
            reduce(.showTopFunds)
        } else if normalized.contains("coffee") || normalized.contains("tired") {
            reduce(.startCoffeeJourney)
        } else if normalized == "confirm" || normalized.contains("pay") {
            reduce(.confirmPayment)
        } else if normalized.contains("great") && normalized.contains("drink") {
            reduce(.startCoffeeJourney)
        } else {
            appendAssistant("I can help bind HSBC, show your portfolio, show top funds, or find coffee nearby.")
        }
    }

    private func createConsentRequest() async {
        do {
            let request = try await environment.consentService.createConsentRequest()
            reduce(.consentRequestCreated(request))
        } catch {
            reduce(.setError(AppError.serviceUnavailable.message))
        }
    }

    private func loadCoffeeShops() async {
        do {
            _ = try await environment.weatherService.currentWeatherSummary()
            let shops = try await environment.coffeeService.nearbyCoffeeShops()
            reduce(.shopsLoaded(shops))
        } catch {
            reduce(.setError(AppError.serviceUnavailable.message))
        }
    }

    private func authorizeAndPay(order: CoffeeOrder, token: OAuthToken) async {
        do {
            let authorization = try await environment.dspAuthorizationService.authorizePayment(
                order: order,
                token: token,
                biometricAssertion: "mock-face-assertion"
            )
            guard authorization.decision == .approved else {
                throw AppError.paymentDeclined
            }
            let receipt = try await environment.paymentService.pay(order: order, token: token)
            reduce(.paymentCompleted(.success(receipt)))
        } catch {
            reduce(.paymentCompleted(.failure(.paymentDeclined)))
        }
    }

    private func appendUser(_ text: String) {
        state.messages.append(ChatMessage(role: .user, text: text))
    }

    private func appendAssistant(_ text: String, attachment: ChatAttachment? = nil) {
        state.messages.append(ChatMessage(role: .assistant, text: text, attachment: attachment))
    }
}
