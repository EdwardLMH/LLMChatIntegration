import XCTest
@testable import SharedOpenBankingKit

@MainActor
final class AppStoreTests: XCTestCase {
    func testConsentCallbackConnectsHSBC() {
        let store = AppStore(initialState: AppState(), environment: .preview)
        let token = ConsentCallbackParser.tokenFromSuccessfulCallback(accountMask: "4321")

        store.send(.hsbcAppReturned(.success(token)))

        guard case let .connected(connectedToken) = store.state.consentStatus else {
            return XCTFail("Expected connected consent")
        }
        XCTAssertEqual(connectedToken.accountMask, "4321")
    }

    func testCreateOrderRequiresSelectedShopAndItem() {
        let store = AppStore(initialState: AppState(), environment: .preview)

        store.send(.createOrder)

        XCTAssertNil(store.state.currentOrder)
    }

    func testConfirmPaymentRequiresConsent() {
        let store = AppStore(initialState: AppState(), environment: .preview)
        let shop = SeedData.shops[0]

        store.send(.selectShop(shop))
        store.send(.selectCoffee(shop.menu[0]))
        store.send(.createOrder)
        store.send(.confirmPayment)

        XCTAssertEqual(store.state.errorMessage, AppError.missingConsent.message)
        XCTAssertFalse(store.state.isShowingFaceVerification)
    }

    func testConsentDeepLinkRoutesToBankingApp() async throws {
        let request = try await MockConsentService().createConsentRequest()

        guard case let .hsbcConsent(parsedRequest) = AppURLRouter.route(request.redirectURL) else {
            return XCTFail("Expected HSBC consent route")
        }

        XCTAssertEqual(parsedRequest.id, request.id)
        XCTAssertEqual(parsedRequest.clientId, "chatgpt-coffee")
        XCTAssertEqual(parsedRequest.callbackURL.absoluteString, "chatgpt://hsbc/consent-callback")
        XCTAssertEqual(parsedRequest.scopes, request.scopes)
    }

    func testBankingAppIssuesCallbackTokenForChatApp() {
        let request = ConsentRequest(
            clientId: "chatgpt-coffee",
            redirectURL: URL(string: "hsbc-mobile://open-banking/consent")!,
            callbackURL: URL(string: "chatgpt://hsbc/consent-callback")!,
            scopes: [.readAccounts, .submitCoffeePayment],
            merchantCategories: ["coffee"],
            validityDays: 30
        )
        let token = ConsentCallbackParser.tokenFromSuccessfulCallback(
            accountMask: "9876",
            scopes: request.scopes,
            consentId: request.id
        )

        guard case let .chatConsentCallback(.success(parsedToken)) = AppURLRouter.route(token.callbackURL(baseURL: request.callbackURL)) else {
            return XCTFail("Expected chat consent callback route")
        }

        XCTAssertEqual(parsedToken.accountMask, "9876")
        XCTAssertEqual(parsedToken.scopes, [.readAccounts, .submitCoffeePayment])
        XCTAssertEqual(parsedToken.consentId, request.id)
    }
}
