# HSBC DSP Authorization Agent via MCP Design

## Purpose

This prototype demonstrates how ChatGPTCoffee can partner with HSBC to support conversational wealth and shopping journeys while keeping banking consent, OAuth token issuance, biometric verification, DSP authorization, and payment execution inside clearly separated trust boundaries.

The current implementation supports account binding, A2UI wealth cards, and coffee ordering, while the MCP mock also defines hotel and flight scenarios so HSBC developers can describe when ChatGPTCoffee should call each API.

## System Overview

For standalone component and sequence diagrams, see [DIAGRAMS.md](DIAGRAMS.md).

## High-Level Architecture

```mermaid
flowchart LR
    User[Customer]

    subgraph ChatGPT[ChatGPTCoffee Experience]
        ChatUI[ChatGPTCoffee iOS App<br/>ChatGPTCoffeeApp]
        AppStore[AppStore<br/>Redux state + routing]
        Cards[Chat Attachments + A2UI<br/>bind, portfolio, top funds, shops, order, receipt]
        FaceSheet[FaceVerificationView sheet<br/>payment biometric step-up]
    end

    subgraph HSBCMobile[HSBC Mobile Banking]
        ConsentUI[ConsentReviewCard<br/>scope review + approve/decline]
        BankFace[BankingFaceVerificationView<br/>consent biometric]
        TokenIssuer[MockOAuthTokenIssuer<br/>OAuth token issuance]
    end

    subgraph HSBCMCP[HSBC Developer MCP Layer]
        ScenarioRouter[Scenario Routing Rules<br/>docs/scenario-routing.md]
        ToolCatalog[MCP Tool Catalog<br/>mcp-tools.json]
        MockServer[Mock Server<br/>src/mock-server.ts]
    end

    subgraph PartnerAPIs[Partner Commerce APIs]
        Coffee[Coffee Shops and Menus]
        Hotels[Hotels]
        Flights[Flights]
    end

    subgraph HSBCPlatform[HSBC Platform APIs]
        OpenBanking[Open Banking APIs<br/>consent, token, quote, payment]
        DSP[HSBC DSP Authorization Agent<br/>risk, step-up, dspAuthorizationId]
    end

    User --> ChatUI
    ChatUI --> AppStore
    AppStore --> Cards
    AppStore --> FaceSheet
    ChatUI -- hsbc-mobile://open-banking/consent --> ConsentUI
    ConsentUI --> BankFace
    BankFace --> TokenIssuer
    TokenIssuer -- chatgpt://hsbc/consent-callback --> ChatUI

    AppStore -. future: tool calls .- HSBCMCP
    ScenarioRouter --> ToolCatalog --> MockServer
    MockServer -. production replacement .- PartnerAPIs
    MockServer -. production replacement .- OpenBanking
    MockServer -. production replacement .- DSP
    DSP -- dspAuthorizationId --> OpenBanking
```

```mermaid
flowchart LR
    User[User]
    ChatApp[ChatGPTCoffeeApp<br/>iOS chat app]
    BankApp[HSBCBankingMockApp<br/>HSBC mobile banking mock]
    Shared[SharedOpenBankingKit<br/>SwiftUI + Redux + models]
    MCP[MockOpenBankingMCP<br/>HSBC developer MCP contract]
    Commerce[Commerce and Travel APIs<br/>coffee, hotel, flight]
    OpenBanking[HSBC Open Banking APIs<br/>consent, token, quote, payment]
    DSP[HSBC DSP Authorization Agent<br/>risk + biometric authorization]

    User --> ChatApp
    ChatApp --> Shared
    BankApp --> Shared
    ChatApp -- "hsbc-mobile://open-banking/consent?..." --> BankApp
    BankApp -- "chatgpt://hsbc/consent-callback?..." --> ChatApp
    ChatApp -. future backend integration .-> MCP
    MCP --> Commerce
    MCP --> OpenBanking
    MCP --> DSP
    DSP --> OpenBanking
```

## Codebase Structure

| Area | Path | Responsibility |
| --- | --- | --- |
| ChatGPTCoffee iOS app | `ChatGPTCoffeeApp/` | Native app shell that hosts the chat wealth and shopping experience. |
| HSBC banking mock app | `HSBCBankingMockApp/` | Native app shell that handles consent review, facial verification, and OAuth token callback. |
| Shared Swift package | `SharedOpenBankingKit/` | SwiftUI views, Redux-style state management, domain models, routing, and mock services. |
| MCP/backend mock | `MockOpenBankingMCP/` | OpenAPI contracts, MCP tool schemas, scenario routing rules, and TypeScript mock handlers. |

## Trust Boundaries

| Boundary | What It Owns | Current Mock |
| --- | --- | --- |
| ChatGPTCoffee app | Conversation, A2UI wealth cards, shop browsing, order card, explicit user confirmation, payment initiation. | `AppStore`, `ChatView`, `WealthViews`, `CoffeeViews`. |
| HSBC mobile banking app | Account consent, facial authentication for consent, OAuth token issuance. | `BankingAppStore`, `BankingRootView`, `MockOAuthTokenIssuer`. |
| HSBC Open Banking | Consent creation, OAuth token exchange, payment quote, final payment submission. | `MockConsentService`, `MockPaymentService`, `hsbc-openbanking.yaml`. |
| HSBC DSP Authorization Agent | Payment risk decision, step-up biometric requirement, one-payment authorization reference. | `DSPAuthorizationServicing`, `MockDSPAuthorizationService`, `hsbc_dsp_authorize_payment`. |
| HSBC developer MCP | Tool definitions, A2UI payloads, and scenario guidance so ChatGPTCoffee knows which API to call and which UI component to render for each user intent. | `mcp-tools.json`, `docs/scenario-routing.md`, `src/mock-server.ts`. |

## Journey 1: Bind HSBC Account

User intent: "I want to bind my HSBC account."

```mermaid
sequenceDiagram
    actor User
    participant RootView as RootView (ChatApp)
    participant Chat as ChatView
    participant Store as AppStore
    participant Consent as MockConsentService
    participant HSBC as BankingRootView (HSBCApp)
    participant BankStore as BankingAppStore
    participant Token as MockOAuthTokenIssuer

    User->>Chat: I want to bind my HSBC account
    Chat->>Store: send(.sendMessage)
    Store->>Store: routeUserMessage detects "bind" or "hsbc"
    Store->>Consent: createConsentRequest()
    Consent-->>Store: ConsentRequest (scopes, redirectURL, callbackURL)
    Store-->>Chat: Append BindHSBCCard with "Open HSBC" action
    User->>Chat: Tap "Open HSBC"
    Chat->>Store: send(.openHSBCAppRequested)
    Store->>Store: hsbcDeepLinkToOpen = request.redirectURL, consentStatus = .authorizing
    RootView->>HSBC: openURL(hsbc-mobile://open-banking/consent?...)
    HSBC->>BankStore: send(.handleIncomingURL(url))
    BankStore->>BankStore: AppURLRouter → .hsbcConsent(ConsentRequest), pendingRequest set
    HSBC-->>User: Show ConsentReviewCard (scopes, Authorize / Decline)
    User->>HSBC: Tap "Authorize"
    HSBC->>BankStore: send(.approveConsentTapped)
    BankStore->>BankStore: isShowingFaceVerification = true
    HSBC-->>User: Show BankingFaceVerificationView sheet
    User->>HSBC: Tap "Verify & Authorize"
    HSBC->>BankStore: send(.faceVerificationCompleted(true))
    BankStore->>Token: issueToken(for: ConsentApproval)
    Token-->>BankStore: OAuthToken
    BankStore->>BankStore: callbackURLToOpen set
    HSBC->>RootView: openURL(chatgpt://hsbc/consent-callback?access_token=...&consent_id=...)
    RootView->>Store: send(.handleIncomingURL(url))
    Store->>Store: AppURLRouter → .chatConsentCallback(.success), consentStatus = .connected(token)
    Store-->>Chat: Append "HSBC is connected" message
```

Implementation notes:

- `ConsentRequest` contains `clientId`, `callbackURL`, OAuth scopes, merchant categories, and validity.
- The current prototype uses custom URL schemes:
  - `hsbc-mobile://open-banking/consent`
  - `chatgpt://hsbc/consent-callback`
- Production should use universal links and OAuth authorization code + PKCE.
- OAuth token scope includes:
  - `accounts:read`
  - `payment-quote:create`
  - `dsp-payment:authorize`
  - `coffee-payment:submit`
  - `travel-payment:submit` for future hotel/flight journeys.

## Journey 2: Wealth A2UI Cards

User intents: "What is my profollio?" and "What are my top funds?"

```mermaid
sequenceDiagram
    actor User
    participant Chat as ChatView
    participant Store as AppStore
    participant MCP as MockOpenBankingMCP
    participant A2UI as A2UI Renderer

    User->>Chat: What is my profollio?
    Chat->>Store: send(.sendMessage)
    Store->>Store: routeUserMessage detects "portfolio", "profollio", or "portfollio"
    Store->>MCP: hsbc_get_portfolio_summary(consentId)
    MCP-->>Store: a2ui.component = portfolioSummary
    Store-->>Chat: ChatAttachment.portfolioSummary
    Chat->>A2UI: Render PortfolioSummaryCard
    User->>Chat: What are my top funds?
    Chat->>Store: send(.sendMessage)
    Store->>MCP: hsbc_get_top_funds(consentId)
    MCP-->>Store: a2ui.component = topFunds
    Store-->>Chat: ChatAttachment.topFunds
    Chat->>A2UI: Render TopFundsCard
    User->>Chat: It is great, I want to drink one coffee
    Chat->>Store: send(.startCoffeeJourney)
```

Implementation notes:

- A2UI means the agent returns a typed JSON UI payload, for example `a2ui.component = "portfolioSummary"` or `a2ui.component = "topFunds"`.
- The Swift prototype renders those payloads as `ChatAttachment.portfolioSummary` and `ChatAttachment.topFunds` inside `ChatView`.
- Portfolio values are non-zero and intentionally make `Funds&Related` the largest allocation for the prototype data set.
- Wealth data requires connected HSBC consent before rendering.

## Journey 3: Coffee Discovery, Order, DSP Authorization, Payment

User intent: "I am tired, I want coffee."

```mermaid
sequenceDiagram
    actor User
    participant RootView as RootView (ChatApp)
    participant Chat as ChatView
    participant Store as AppStore
    participant Weather as MockWeatherService
    participant Coffee as MockCoffeeService
    participant DSP as MockDSPAuthorizationService
    participant Pay as MockPaymentService

    User->>Chat: I am tired, I want coffee
    Chat->>Store: send(.sendMessage)
    Store->>Store: routeUserMessage detects "coffee" or "tired"
    Note over Store,Coffee: loadCoffeeShops() — sequential async calls
    Store->>Weather: currentWeatherSummary()
    Weather-->>Store: "Cool and cloudy, 18C"
    Store->>Coffee: nearbyCoffeeShops()
    Coffee-->>Store: [CoffeeShop]
    Store-->>Chat: ShopCarousel attachment in chat
    User->>Chat: Tap menu item, then tap "Order" on ShopCard
    Chat->>Store: send(.selectShop) + send(.selectCoffee) + send(.createOrder)
    Store->>Store: CoffeeOrder(status: .awaitingConfirmation)
    Store-->>Chat: OrderCard attachment + "Please confirm or tap Pay"
    Chat-->>User: Weather-related message and confirmation prompt
    User->>Chat: Type "confirm" or tap Pay on OrderCard
    Chat->>Store: send(.confirmPayment)
    Store->>Store: isShowingFaceVerification = true, order.status = .verifyingFace
    RootView-->>User: Show FaceVerificationView sheet
    User->>RootView: Tap "Verify & Pay"
    RootView->>Store: send(.faceVerificationCompleted(true))
    Store->>DSP: authorizePayment(order, token, biometricAssertion: "mock-face-assertion")
    DSP-->>Store: DSPPaymentAuthorization(decision: .approved, riskScore: 18)
    Store->>Pay: pay(order, token)
    Pay-->>Store: PaymentReceipt
    Store-->>Chat: ReceiptCard attachment in chat
```

Current Swift mock behavior:

- `routeUserMessage` starts the coffee journey when the message contains `coffee` or `tired`.
- `loadCoffeeShops` combines weather and nearby coffee data.
- `createOrder` creates a `CoffeeOrder` with `awaitingConfirmation` status.
- `confirmPayment` requires a connected HSBC OAuth token.
- `faceVerificationCompleted(true)` calls `authorizeAndPay`.
- `authorizeAndPay` first calls `DSPAuthorizationServicing`, then calls `PaymentServicing`.

## MCP Tool Flow

HSBC developers provide MCP tool definitions so ChatGPTCoffee can map user scenarios to API calls and A2UI component payloads.

```mermaid
flowchart TD
    Intent[User intent in chat]
    Router[Scenario routing rules<br/>provided by HSBC MCP]
    Consent[hsbc_create_consent_link]
    Portfolio[hsbc_get_portfolio_summary<br/>A2UI portfolioSummary]
    TopFunds[hsbc_get_top_funds<br/>A2UI topFunds]
    CoffeeSearch[commerce_search_coffee]
    CoffeeOrder[commerce_create_coffee_order]
    HotelSearch[travel_search_hotels]
    HotelBooking[travel_create_hotel_booking]
    FlightSearch[travel_search_flights]
    FlightBooking[travel_create_flight_booking]
    Quote[hsbc_create_payment_quote]
    Confirm[Explicit user confirmation]
    Biometric[Facial verification]
    DSP[hsbc_dsp_authorize_payment]
    Submit[hsbc_submit_payment]

    Intent --> Router
    Router -->|bind HSBC| Consent
    Router -->|portfolio| Portfolio
    Router -->|top funds| TopFunds
    Router -->|coffee| CoffeeSearch --> CoffeeOrder --> Quote
    Router -->|hotel| HotelSearch --> HotelBooking --> Quote
    Router -->|flight| FlightSearch --> FlightBooking --> Quote
    Quote --> Confirm --> Biometric --> DSP --> Submit
```

MCP tools currently defined:

| Tool | When ChatGPTCoffee Should Use It |
| --- | --- |
| `hsbc_create_consent_link` | User wants to bind/connect HSBC or use HSBC for payment. |
| `hsbc_get_portfolio_summary` | Connected user asks for portfolio, profollio, portfollio, holdings, or asset allocation; returns `portfolioSummary` A2UI. |
| `hsbc_get_top_funds` | Connected user asks for top funds, top 3 funds, top performers, or fund ranking; returns `topFunds` A2UI. |
| `commerce_search_coffee` | User wants coffee, caffeine, nearby cafes, Starbucks, Luckin, or drink recommendations. |
| `commerce_create_coffee_order` | User selected a coffee shop and menu item. |
| `travel_search_hotels` | User wants hotel/accommodation. |
| `travel_create_hotel_booking` | User selected hotel and room. |
| `travel_search_flights` | User wants flight/airline tickets. |
| `travel_create_flight_booking` | User selected flight itinerary. |
| `hsbc_create_payment_quote` | An unpaid order or booking exists before final payment confirmation. |
| `hsbc_dsp_authorize_payment` | User explicitly confirms payment and DSP must authorize this specific transaction. |
| `hsbc_submit_payment` | DSP returned an approved `dspAuthorizationId`. |

## DSP Authorization Model

OAuth consent and DSP authorization are intentionally different.

```mermaid
flowchart LR
    OAuth[OAuth token<br/>API access permission]
    Order[Visible order summary]
    Confirm[Explicit user confirmation]
    Face[Facial verification]
    DSP[HSBC DSP Authorization Agent]
    AuthRef[dspAuthorizationId]
    Payment[Open Banking payment submission]

    OAuth --> DSP
    Order --> DSP
    Confirm --> DSP
    Face --> DSP
    DSP -->|approved| AuthRef --> Payment
    DSP -->|declined or step-up required| Stop[Do not submit payment]
```

Rules:

- OAuth token means ChatGPTCoffee is allowed to call permitted HSBC APIs.
- DSP authorization means this specific payment is approved.
- ChatGPTCoffee must not submit payment based only on inferred user intent.
- ChatGPTCoffee must show a visible order or booking summary before payment.
- ChatGPTCoffee must require explicit confirmation, such as typing `confirm` or tapping Pay.
- Final payment submission must include a DSP authorization reference.

## Redux State and Actions

ChatGPTCoffee uses a Redux-style store:

```mermaid
stateDiagram-v2
    [*] --> disconnected
    disconnected --> pendingRedirect: startHSBCBinding
    pendingRedirect --> authorizing: openHSBCAppRequested
    authorizing --> connected: hsbcAppReturned(success)
    authorizing --> failed: hsbcAppReturned(failure)
    connected --> wealth: showPortfolio / showTopFunds
    wealth --> coffeeOrder: startCoffeeJourney
    connected --> coffeeOrder: startCoffeeJourney
    coffeeOrder --> awaitingConfirmation: createOrder
    awaitingConfirmation --> verifyingFace: confirmPayment
    verifyingFace --> paid: faceVerificationCompleted(true) / DSP approved + payment paid
    verifyingFace --> failedPayment: faceVerificationCompleted(false)
```

Important state:

- `consentStatus`: disconnected, pending redirect, authorizing, connected, or failed.
- `messages`: chat history and assistant cards.
- `PortfolioSummary`, `TopFundsList`: wealth A2UI data rendered in chat.
- `shops`, `selectedShop`, `selectedItem`: coffee browsing state.
- `currentOrder`: order summary and status.
- `receipt`: payment result.
- `isShowingFaceVerification`: controls the face verification sheet.

Important actions:

- Consent: `startHSBCBinding`, `consentRequestCreated`, `openHSBCAppRequested`, `handleIncomingURL`, `hsbcAppReturned`.
- Wealth: `showPortfolio`, `showTopFunds`.
- Coffee: `startCoffeeJourney`, `shopsLoaded`, `selectShop`, `selectCoffee`, `createOrder`.
- Payment: `confirmPayment`, `faceVerificationCompleted`, `paymentCompleted`.

## Domain Model Summary

| Model | Purpose |
| --- | --- |
| `ConsentRequest` | Request sent from ChatGPTCoffee to HSBC app for user consent. |
| `OAuthToken` | Mock token returned after HSBC consent. Includes scopes, expiry, account mask, and consent ID. |
| `HSBCScope` | Open Banking and DSP permissions. |
| `PortfolioSummary`, `PortfolioCategory`, `TopFundsList`, `TopFund` | Wealth data returned through A2UI and rendered in chat. |
| `CoffeeShop`, `CoffeeItem`, `CoffeeOrder` | Merchant discovery and order summary. |
| `DSPPaymentAuthorization` | DSP decision for a specific payment quote/order. |
| `PaymentReceipt` | Final paid transaction result. |
| `ChatMessage`, `ChatAttachment` | Chat transcript plus rich A2UI cards for binding, portfolio, top funds, shops, order, and receipt. |

## API Contracts

OpenAPI contracts live in:

- `MockOpenBankingMCP/openapi/hsbc-openbanking.yaml`
- `MockOpenBankingMCP/openapi/commerce-travel.yaml`

Key HSBC Open Banking endpoints:

- `POST /consents`
- `POST /oauth/token`
- `POST /payment-quotes`
- `POST /dsp/payment-authorizations`
- `POST /payments`
- `GET /payments/{paymentId}`

The current iOS app still uses local Swift mock services. The OpenAPI and MCP files define the intended backend contract for replacing local mocks later.

## Production Hardening

Before production, replace the mock pieces with:

- OAuth authorization code + PKCE and universal links.
- Secure token exchange and storage, preferably server-side with Keychain only for client secrets that belong on device.
- Real HSBC DSP risk policy, signed biometric assertions, device binding, replay protection, and audit logging.
- Idempotency keys for payment submission.
- Consent revocation and token refresh.
- Clear merchant identity, amount, currency, pickup/booking details, and cancellation policy before confirmation.
- Server-side MCP implementation with strict tool allowlists and payment safety checks.
