# Component and Sequence Diagrams

## High-Level Architecture Diagram

```mermaid
flowchart LR
    User[Customer]

    subgraph ChatGPT[ChatGPT Experience]
        ChatUI[ChatGPT-like iOS App]
        Conversation[Conversation Orchestration]
        Cards[Shopping Cards<br/>shops, menus, orders, receipts]
    end

    subgraph HSBCMobile[HSBC Mobile Banking]
        ConsentUI[Consent Review]
        BankFace[HSBC Facial Authentication]
        TokenIssuer[OAuth Token Issuance]
    end

    subgraph HSBCMCP[HSBC Developer MCP Layer]
        ScenarioRouter[Scenario Routing Rules]
        ToolCatalog[MCP Tool Catalog]
        ToolExecutor[MCP Tool Executor]
    end

    subgraph PartnerAPIs[Partner Commerce APIs]
        Coffee[Coffee Shops and Menus]
        Hotels[Hotels]
        Flights[Flights]
    end

    subgraph HSBCPlatform[HSBC Platform APIs]
        OpenBanking[Open Banking APIs<br/>consent, token, quote, payment]
        DSP[HSBC DSP Authorization Agent<br/>risk, step-up, authorization]
    end

    User --> ChatUI
    ChatUI --> Conversation
    Conversation --> Cards
    ChatUI -- bind account deep link --> ConsentUI
    ConsentUI --> BankFace
    BankFace --> TokenIssuer
    TokenIssuer -- OAuth callback --> ChatUI

    Conversation -- tool calls --> HSBCMCP
    ScenarioRouter --> ToolCatalog --> ToolExecutor
    ToolExecutor --> PartnerAPIs
    ToolExecutor --> OpenBanking
    ToolExecutor --> DSP
    DSP -- dspAuthorizationId --> OpenBanking
    OpenBanking -- payment result --> ToolExecutor
    ToolExecutor -- tool results --> Conversation
    Conversation --> ChatUI
```

## Component Diagram

```mermaid
flowchart TB
    User[User]

    subgraph IOS[iOS Simulator / iPhone]
        subgraph ChatApp[ChatGPTCoffeeApp]
            ChatRoot[ChatGPTLikeDemoRoot]
            RootView[RootView]
            ChatView[ChatView]
            CoffeeViews[ShopCarousel / OrderCard / ReceiptCard]
            ConsentViews[BindHSBCCard / FaceVerificationView]
        end

        subgraph BankApp[HSBCBankingMockApp]
            BankRoot[HSBCBankingDemoRoot]
            BankingView[BankingRootView]
            ConsentReview[ConsentReviewCard]
            BankFace[BankingFaceVerificationView]
        end

        subgraph Shared[SharedOpenBankingKit]
            AppStore[AppStore]
            AppState[AppState / AppAction]
            BankStore[BankingAppStore]
            BankState[BankingAppState / BankingAppAction]
            Router[AppURLRouter]
            Models[Domain Models]
            ConsentService[MockConsentService]
            OAuthIssuer[MockOAuthTokenIssuer]
            CoffeeService[MockCoffeeService]
            WeatherService[MockWeatherService]
            DSPService[MockDSPAuthorizationService]
            PaymentService[MockPaymentService]
            Biometric[LocalBiometricAuthorizer]
        end
    end

    subgraph MCP[MockOpenBankingMCP]
        ToolSchemas[mcp-tools.json]
        ScenarioRules[docs/scenario-routing.md]
        MockServer[src/mock-server.ts]
        HSBCOpenAPI[openapi/hsbc-openbanking.yaml]
        CommerceOpenAPI[openapi/commerce-travel.yaml]
        SeedData[data/*.json]
    end

    subgraph Backend[Future Production Services]
        CommerceAPI[Commerce / Travel APIs]
        OpenBankingAPI[HSBC Open Banking APIs]
        DSPAgent[HSBC DSP Authorization Agent]
    end

    User --> ChatView
    User --> BankingView

    ChatRoot --> RootView --> ChatView
    ChatView --> CoffeeViews
    ChatView --> ConsentViews
    RootView --> AppStore
    AppStore --> AppState
    AppStore --> ConsentService
    AppStore --> CoffeeService
    AppStore --> WeatherService
    AppStore --> DSPService
    AppStore --> PaymentService
    RootView --> Router

    BankRoot --> BankingView
    BankingView --> ConsentReview
    BankingView --> BankFace
    BankingView --> BankStore
    BankStore --> BankState
    BankStore --> OAuthIssuer
    BankStore --> Router

    ConsentService --> Models
    OAuthIssuer --> Models
    CoffeeService --> Models
    DSPService --> Models
    PaymentService --> Models

    ChatApp -- hsbc-mobile://open-banking/consent --> BankApp
    BankApp -- chatgpt://hsbc/consent-callback --> ChatApp

    ToolSchemas --> MockServer
    ScenarioRules --> MockServer
    HSBCOpenAPI --> MockServer
    CommerceOpenAPI --> MockServer
    SeedData --> MockServer

    MockServer -. production replacement .-> CommerceAPI
    MockServer -. production replacement .-> OpenBankingAPI
    MockServer -. production replacement .-> DSPAgent
    DSPAgent --> OpenBankingAPI
```

## Sequence Diagram: HSBC Account Binding and OAuth Token

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant ChatUI as ChatGPTCoffeeApp UI
    participant AppStore as AppStore
    participant ConsentSvc as MockConsentService
    participant Router as AppURLRouter
    participant HSBCUI as HSBCBankingMockApp UI
    participant BankStore as BankingAppStore
    participant TokenIssuer as MockOAuthTokenIssuer

    User->>ChatUI: Type "I want to bind my HSBC account"
    ChatUI->>AppStore: send(.sendMessage)
    AppStore->>AppStore: routeUserMessage detects bind/HSBC
    AppStore->>ConsentSvc: createConsentRequest()
    ConsentSvc-->>AppStore: ConsentRequest with scopes and callback URL
    AppStore-->>ChatUI: Append BindHSBCCard
    User->>ChatUI: Tap Open HSBC
    ChatUI->>AppStore: send(.openHSBCAppRequested)
    AppStore-->>ChatUI: hsbcDeepLinkToOpen
    ChatUI->>HSBCUI: Open hsbc-mobile://open-banking/consent
    HSBCUI->>BankStore: send(.handleIncomingURL)
    BankStore->>Router: route(url)
    Router-->>BankStore: hsbcConsent(ConsentRequest)
    BankStore-->>HSBCUI: Show consent review
    User->>HSBCUI: Approve consent
    HSBCUI->>BankStore: send(.approveConsentTapped)
    BankStore-->>HSBCUI: Show facial verification
    User->>HSBCUI: Complete facial verification
    HSBCUI->>BankStore: send(.faceVerificationCompleted(true))
    BankStore->>TokenIssuer: issueToken(for: ConsentApproval)
    TokenIssuer-->>BankStore: OAuthToken
    BankStore-->>HSBCUI: callbackURLToOpen
    HSBCUI->>ChatUI: Open chatgpt://hsbc/consent-callback
    ChatUI->>AppStore: send(.handleIncomingURL)
    AppStore->>Router: route(url)
    Router-->>AppStore: chatConsentCallback(success token)
    AppStore-->>ChatUI: consentStatus = connected(OAuthToken)
```

## Sequence Diagram: Coffee Order, DSP Authorization, Payment

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant ChatUI as ChatGPTCoffeeApp UI
    participant AppStore as AppStore
    participant WeatherSvc as MockWeatherService
    participant CoffeeSvc as MockCoffeeService
    participant Face as FaceVerificationView
    participant DSP as MockDSPAuthorizationService
    participant PaymentSvc as MockPaymentService

    User->>ChatUI: Type "I am tired, I want coffee"
    ChatUI->>AppStore: send(.sendMessage)
    AppStore->>AppStore: routeUserMessage detects coffee/tired
    AppStore->>WeatherSvc: currentWeatherSummary()
    WeatherSvc-->>AppStore: "Cool and cloudy, 18C"
    AppStore->>CoffeeSvc: nearbyCoffeeShops()
    CoffeeSvc-->>AppStore: [CoffeeShop]
    AppStore-->>ChatUI: Append shopCarousel attachment
    User->>ChatUI: Select shop
    ChatUI->>AppStore: send(.selectShop)
    User->>ChatUI: Select coffee item
    ChatUI->>AppStore: send(.selectCoffee)
    User->>ChatUI: Press Order
    ChatUI->>AppStore: send(.createOrder)
    AppStore-->>ChatUI: Append orderCard with Pay button
    AppStore-->>ChatUI: Ask for confirm or Pay
    User->>ChatUI: Type confirm or tap Pay
    ChatUI->>AppStore: send(.confirmPayment)

    alt HSBC consent missing
        AppStore-->>ChatUI: Ask user to bind HSBC first
    else HSBC consent connected
        AppStore-->>Face: Show facial verification
        User->>Face: Complete face check
        Face->>AppStore: send(.faceVerificationCompleted(true))
        AppStore->>DSP: authorizePayment(order, token, biometricAssertion)
        DSP-->>AppStore: DSPPaymentAuthorization(decision: approved)
        AppStore->>PaymentSvc: pay(order, token)
        PaymentSvc-->>AppStore: PaymentReceipt
        AppStore-->>ChatUI: Append paymentReceipt attachment
    end
```

## Sequence Diagram: Future MCP Tool Orchestration

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant ChatGPT as ChatGPT Runtime
    participant MCP as HSBC Commerce + DSP MCP Server
    participant Commerce as Commerce / Travel API
    participant OpenBanking as HSBC Open Banking API
    participant DSP as HSBC DSP Authorization Agent

    User->>ChatGPT: Shopping or travel request
    ChatGPT->>MCP: Read scenario routing and available tools

    alt Bind HSBC account
        ChatGPT->>MCP: hsbc_create_consent_link
        MCP->>OpenBanking: POST /consents
        OpenBanking-->>MCP: consentId + authorizationUrl
        MCP-->>ChatGPT: bind link/card data
        ChatGPT-->>User: Show bind HSBC card
    else Coffee request
        ChatGPT->>MCP: commerce_search_coffee
        MCP->>Commerce: Search nearby coffee shops
        Commerce-->>MCP: coffee shops and menus
        MCP-->>ChatGPT: coffee results
        ChatGPT-->>User: Show shop/menu cards
        User->>ChatGPT: Select item and order
        ChatGPT->>MCP: commerce_create_coffee_order
        MCP->>Commerce: Create unpaid order
        Commerce-->>MCP: orderId, merchantId, amount
        MCP-->>ChatGPT: unpaid order
    else Hotel or flight request
        ChatGPT->>MCP: travel_search_hotels or travel_search_flights
        MCP->>Commerce: Search travel inventory
        Commerce-->>MCP: options
        MCP-->>ChatGPT: options
        User->>ChatGPT: Select booking
        ChatGPT->>MCP: travel_create_hotel_booking or travel_create_flight_booking
        MCP->>Commerce: Create unpaid booking
        Commerce-->>MCP: booking/order data
        MCP-->>ChatGPT: unpaid booking
    end

    ChatGPT-->>User: Show visible order or booking summary
    User->>ChatGPT: Confirm payment
    ChatGPT->>MCP: hsbc_create_payment_quote
    MCP->>OpenBanking: POST /payment-quotes
    OpenBanking-->>MCP: quoteId + riskDecision
    MCP-->>ChatGPT: payment quote
    ChatGPT-->>User: Facial verification challenge
    User->>ChatGPT: Complete facial verification
    ChatGPT->>MCP: hsbc_dsp_authorize_payment
    MCP->>DSP: Authorize quote + consent + biometric assertion
    DSP-->>MCP: approved dspAuthorizationId
    MCP-->>ChatGPT: DSP authorization result
    ChatGPT->>MCP: hsbc_submit_payment
    MCP->>OpenBanking: POST /payments with dspAuthorizationId
    OpenBanking-->>MCP: payment receipt
    MCP-->>ChatGPT: payment receipt
    ChatGPT-->>User: Show receipt in chat
```
