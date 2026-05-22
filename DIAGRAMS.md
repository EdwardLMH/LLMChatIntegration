# Component and Sequence Diagrams

## High-Level Architecture Diagram

```mermaid
flowchart LR
    User(["👤 Customer"])

    subgraph ChatGPTCoffee["ChatGPTCoffee Experience"]
        direction TB
        ChatUI["📱 ChatGPTCoffee iOS App\nChatGPTCoffeeApp"]
        AppStore["🗃️ AppStore\nRedux state + routing"]
        Cards["🃏 Chat Attachments + A2UI\nbind · portfolio · top funds · shops · order · receipt"]
        FaceSheet["🔐 FaceVerificationView\npayment biometric step-up"]
    end

    subgraph HSBCMobile["🏦  HSBC Mobile Banking"]
        direction TB
        ConsentUI["📋 ConsentReviewCard\nscope review · approve / decline"]
        BankFace["🪪 BankingFaceVerificationView\nconsent biometric"]
        TokenIssuer["🔑 MockOAuthTokenIssuer\nOAuth token issuance"]
    end

    subgraph HSBCMCP["⚙️  HSBC Developer MCP Layer"]
        direction TB
        ScenarioRouter["🗺️ Scenario Routing Rules\ndocs/scenario-routing.md"]
        ToolCatalog["📚 MCP Tool Catalog\nmcp-tools.json"]
        MockServer["🖥️ Mock Server\nsrc/mock-server.ts"]
    end

    subgraph PartnerAPIs["🛍️  Partner Commerce APIs"]
        direction TB
        Coffee["☕ Coffee Shops & Menus"]
        Hotels["🏨 Hotels"]
        Flights["✈️ Flights"]
    end

    subgraph HSBCPlatform["🏛️  HSBC Platform APIs"]
        direction TB
        OpenBanking["🏦 Open Banking APIs\nconsent · token · quote · payment"]
        DSP["🛡️ DSP Authorization Agent\nrisk · step-up · dspAuthorizationId"]
    end

    User --> ChatUI
    ChatUI --> AppStore
    AppStore --> Cards
    AppStore --> FaceSheet
    ChatUI -- "hsbc-mobile://\nopen-banking/consent" --> ConsentUI
    ConsentUI --> BankFace
    BankFace --> TokenIssuer
    TokenIssuer -- "chatgpt://hsbc/\nconsent-callback" --> ChatUI

    AppStore -. "🔮 future: tool calls" .- HSBCMCP
    ScenarioRouter --> ToolCatalog --> MockServer
    MockServer -. "production replacement" .- PartnerAPIs
    MockServer -. "production replacement" .- OpenBanking
    MockServer -. "production replacement" .- DSP
    DSP -- "dspAuthorizationId" --> OpenBanking

    classDef chatgpt  fill:#10a37f,stroke:#0d8a6b,color:#fff
    classDef hsbc     fill:#db0011,stroke:#b5000e,color:#fff
    classDef mcp      fill:#f59e0b,stroke:#d48608,color:#fff
    classDef partner  fill:#6366f1,stroke:#4f52d8,color:#fff
    classDef platform fill:#dc2626,stroke:#b91c1c,color:#fff
    classDef user     fill:#0ea5e9,stroke:#0284c7,color:#fff

    class ChatUI,AppStore,Cards,FaceSheet chatgpt
    class ConsentUI,BankFace,TokenIssuer hsbc
    class ScenarioRouter,ToolCatalog,MockServer mcp
    class Coffee,Hotels,Flights partner
    class OpenBanking,DSP platform
    class User user
```

---

## Component Diagram

```mermaid
flowchart TB
    User(["👤 User"])

    subgraph IOS["📱  iOS Simulator / iPhone"]
        subgraph ChatApp["🤖 ChatGPTCoffeeApp"]
            ChatRoot["HSBCOpenBankingChatDemoRoot\nalias ChatGPTLikeDemoRoot"]
            RootView["RootView\nonOpenURL · sheet · alert · openURL"]
            ChatView["ChatView\nmessages · input bar · status bar"]
            AttachViews["BindHSBCCard · PortfolioSummaryCard · TopFundsCard\nShopCarousel · OrderCard · ReceiptCard"]
            FaceSheet["🔐 FaceVerificationView sheet\npayment step-up"]
        end

        subgraph BankApp["🏦 HSBCBankingMockApp"]
            BankRoot["HSBCBankingDemoRoot"]
            BankingView["BankingRootView\nonOpenURL · sheet · alert · openURL"]
            ConsentReview["ConsentReviewCard\nscopes · Authorize / Decline"]
            BankFace["🪪 BankingFaceVerificationView\nconsent biometric sheet"]
        end

        subgraph Shared["📦 SharedOpenBankingKit"]
            subgraph Redux["Redux Layer"]
                AppStore["AppStore\nreduce · routeUserMessage"]
                AppEnv["AppEnvironment\nconsent · coffee · weather · dsp · payment"]
                AppState["AppState / AppAction"]
                BankStore["BankingAppStore\nreduce · issueToken"]
                BankEnv["BankingAppEnvironment\ntokenIssuer"]
                BankState["BankingAppState / BankingAppAction"]
            end
            subgraph Routing["Routing"]
                Router["AppURLRouter\nhsbcConsent · chatConsentCallback"]
            end
            subgraph Services["Mock Services"]
                ConsentService["MockConsentService"]
                OAuthIssuer["MockOAuthTokenIssuer"]
                CoffeeService["MockCoffeeService"]
                WeatherService["MockWeatherService"]
                DSPService["MockDSPAuthorizationService"]
                PaymentService["MockPaymentService"]
                Biometric["LocalBiometricAuthorizer\n⚠️ not wired into AppEnvironment yet"]
            end
            subgraph ModelLayer["Domain Models"]
                Models["ConsentRequest · OAuthToken\nPortfolioSummary · TopFundsList\nCoffeeOrder · DSPPaymentAuthorization\nPaymentReceipt · ChatMessage"]
            end
        end
    end

    subgraph MCP["⚙️  MockOpenBankingMCP"]
        ToolSchemas["mcp-tools.json"]
        ScenarioRules["docs/scenario-routing.md"]
        MockServer["src/mock-server.ts"]
        HSBCOpenAPI["openapi/hsbc-openbanking.yaml"]
        CommerceOpenAPI["openapi/commerce-travel.yaml"]
        SeedData["data/*.json"]
    end

    subgraph Backend["🌐  Future Production Services"]
        CommerceAPI["Commerce / Travel APIs"]
        OpenBankingAPI["HSBC Open Banking APIs"]
        DSPAgent["HSBC DSP Authorization Agent"]
    end

    User --> ChatView
    User --> BankingView

    ChatRoot --> RootView --> ChatView --> AttachViews
    RootView --> FaceSheet
    RootView --> AppStore --> AppState
    AppStore --> AppEnv
    AppEnv --> ConsentService & CoffeeService & WeatherService & DSPService & PaymentService
    RootView -- "AppURLRouter" --> Router

    BankRoot --> BankingView
    BankingView --> ConsentReview & BankFace & BankStore
    BankStore --> BankState & BankEnv
    BankEnv --> OAuthIssuer
    BankingView -- "AppURLRouter" --> Router

    ConsentService & OAuthIssuer & CoffeeService & DSPService & PaymentService --> Models

    ChatApp -- "🔗 hsbc-mobile://open-banking/consent?..." --> BankApp
    BankApp -- "🔗 chatgpt://hsbc/consent-callback?..." --> ChatApp

    ToolSchemas & ScenarioRules & HSBCOpenAPI & CommerceOpenAPI & SeedData --> MockServer

    MockServer -. "production replacement" .-> CommerceAPI & OpenBankingAPI & DSPAgent
    DSPAgent --> OpenBankingAPI

    classDef chatgptUI  fill:#10a37f,stroke:#0d8a6b,color:#fff
    classDef hsbcUI     fill:#db0011,stroke:#b5000e,color:#fff
    classDef reduxNode  fill:#7c3aed,stroke:#6d28d9,color:#fff
    classDef svcNode    fill:#0ea5e9,stroke:#0284c7,color:#fff
    classDef modelNode  fill:#64748b,stroke:#475569,color:#fff
    classDef mcpNode    fill:#f59e0b,stroke:#d48608,color:#fff
    classDef backendNode fill:#6b7280,stroke:#4b5563,color:#fff,stroke-dasharray:4

    class ChatRoot,RootView,ChatView,AttachViews,FaceSheet chatgptUI
    class BankRoot,BankingView,ConsentReview,BankFace hsbcUI
    class AppStore,AppEnv,AppState,BankStore,BankEnv,BankState,Router reduxNode
    class ConsentService,OAuthIssuer,CoffeeService,WeatherService,DSPService,PaymentService,Biometric svcNode
    class Models modelNode
    class ToolSchemas,ScenarioRules,MockServer,HSBCOpenAPI,CommerceOpenAPI,SeedData mcpNode
    class CommerceAPI,OpenBankingAPI,DSPAgent backendNode
```

---

## Sequence Diagram: HSBC Account Binding and OAuth Token

```mermaid
sequenceDiagram
    autonumber
    actor User as 👤 User
    participant RootView as RootView<br/>(ChatApp)
    participant ChatView as ChatView
    participant AppStore as AppStore
    participant ConsentSvc as MockConsentService
    participant Router as AppURLRouter
    participant BankingView as BankingRootView<br/>(HSBCApp)
    participant BankStore as BankingAppStore
    participant TokenIssuer as MockOAuthTokenIssuer

    rect rgb(236, 253, 245)
        Note over User,AppStore: 💬 Phase 1 — ChatApp initiates consent
        User->>ChatView: "I want to bind my HSBC account"
        activate ChatView
        ChatView->>AppStore: send(.sendMessage)
        deactivate ChatView
        activate AppStore
        AppStore->>AppStore: routeUserMessage → startHSBCBinding
        AppStore->>ConsentSvc: createConsentRequest()
        activate ConsentSvc
        ConsentSvc-->>AppStore: ConsentRequest (scopes, redirectURL, callbackURL)
        deactivate ConsentSvc
        AppStore->>AppStore: consentStatus = .pendingRedirect
        AppStore-->>ChatView: Append BindHSBCCard attachment
        deactivate AppStore
    end

    rect rgb(254, 242, 242)
        Note over User,BankStore: 🏦 Phase 2 — Deep link to HSBCApp + consent review
        User->>ChatView: Tap "Open HSBC" on BindHSBCCard
        activate ChatView
        ChatView->>AppStore: send(.openHSBCAppRequested)
        deactivate ChatView
        activate AppStore
        AppStore->>AppStore: hsbcDeepLinkToOpen set, consentStatus = .authorizing
        deactivate AppStore
        RootView->>BankingView: openURL(hsbc-mobile://open-banking/consent?...)
        activate BankingView
        BankingView->>BankStore: send(.handleIncomingURL(url))
        activate BankStore
        BankStore->>Router: AppURLRouter.route(url)
        activate Router
        Router-->>BankStore: .hsbcConsent(ConsentRequest)
        deactivate Router
        BankStore->>BankStore: pendingRequest = ConsentRequest
        deactivate BankStore
        BankingView-->>User: Show ConsentReviewCard (scopes, Authorize / Decline)
        deactivate BankingView
    end

    rect rgb(255, 251, 235)
        Note over User,TokenIssuer: 🪪 Phase 3 — Facial verification + token issuance
        User->>BankingView: Tap "Authorize"
        activate BankingView
        BankingView->>BankStore: send(.approveConsentTapped)
        activate BankStore
        BankStore->>BankStore: isShowingFaceVerification = true
        deactivate BankStore
        BankingView-->>User: Show BankingFaceVerificationView sheet
        User->>BankingView: Tap "Verify & Authorize"
        BankingView->>BankStore: send(.faceVerificationCompleted(true))
        activate BankStore
        BankStore->>TokenIssuer: issueToken(for: ConsentApproval)
        activate TokenIssuer
        TokenIssuer-->>BankStore: OAuthToken
        deactivate TokenIssuer
        BankStore->>BankStore: callbackURLToOpen set
        deactivate BankStore
        deactivate BankingView
    end

    rect rgb(240, 249, 255)
        Note over RootView,AppStore: ✅ Phase 4 — OAuth callback → ChatApp connected
        BankingView->>RootView: openURL(chatgpt://hsbc/consent-callback?access_token=...&consent_id=...)
        activate RootView
        RootView->>AppStore: send(.handleIncomingURL(url))
        activate AppStore
        AppStore->>Router: AppURLRouter.route(url)
        activate Router
        Router-->>AppStore: .chatConsentCallback(.success(OAuthToken))
        deactivate Router
        AppStore->>AppStore: consentStatus = .connected(token)
        AppStore-->>ChatView: Append "HSBC is connected" message
        deactivate AppStore
        deactivate RootView
    end
```

---

## Sequence Diagram: Coffee Order, DSP Authorization, Payment

```mermaid
sequenceDiagram
    autonumber
    actor User as 👤 User
    participant RootView as RootView<br/>(ChatApp)
    participant ChatView as ChatView
    participant AppStore as AppStore
    participant WeatherSvc as MockWeatherService
    participant CoffeeSvc as MockCoffeeService
    participant DSP as MockDSP<br/>AuthorizationService
    participant PaymentSvc as MockPaymentService

    rect rgb(236, 253, 245)
        Note over User,CoffeeSvc: ☕ Phase 1 — Discover nearby coffee
        User->>ChatView: "I am tired, I want coffee"
        activate ChatView
        ChatView->>AppStore: send(.sendMessage)
        deactivate ChatView
        activate AppStore
        AppStore->>AppStore: routeUserMessage → startCoffeeJourney
        Note over AppStore,CoffeeSvc: loadCoffeeShops() — sequential async calls
        AppStore->>WeatherSvc: currentWeatherSummary()
        activate WeatherSvc
        WeatherSvc-->>AppStore: "Cool and cloudy, 18C"
        deactivate WeatherSvc
        AppStore->>CoffeeSvc: nearbyCoffeeShops()
        activate CoffeeSvc
        CoffeeSvc-->>AppStore: [CoffeeShop]
        deactivate CoffeeSvc
        AppStore->>AppStore: reduce(.shopsLoaded)
        AppStore-->>ChatView: Append ShopCarousel attachment
        deactivate AppStore
    end

    rect rgb(255, 251, 235)
        Note over User,AppStore: 🛒 Phase 2 — Shop selection and order creation
        User->>ChatView: Tap menu item on ShopCard
        activate ChatView
        ChatView->>AppStore: send(.selectShop) + send(.selectCoffee)
        deactivate ChatView
        User->>ChatView: Tap "Order" on ShopCard
        activate ChatView
        ChatView->>AppStore: send(.selectShop) + send(.createOrder)
        deactivate ChatView
        activate AppStore
        AppStore->>AppStore: CoffeeOrder(status: .awaitingConfirmation)
        AppStore-->>ChatView: Append OrderCard + "Please confirm or tap Pay"
        deactivate AppStore
    end

    rect rgb(254, 242, 242)
        Note over User,PaymentSvc: 💳 Phase 3 — Payment authorization
        User->>ChatView: Type "confirm" or tap Pay on OrderCard
        activate ChatView
        ChatView->>AppStore: send(.confirmPayment)
        deactivate ChatView

        alt ❌ HSBC consent not connected
            activate AppStore
            AppStore-->>ChatView: "Please bind HSBC first"
            deactivate AppStore
        else ✅ consentStatus = .connected(token)
            activate AppStore
            AppStore->>AppStore: isShowingFaceVerification = true, order.status = .verifyingFace
            deactivate AppStore
            RootView-->>User: Show FaceVerificationView sheet
            User->>RootView: Tap "Verify & Pay"
            activate RootView
            RootView->>AppStore: send(.faceVerificationCompleted(true))
            deactivate RootView
            activate AppStore
            Note over AppStore,PaymentSvc: authorizeAndPay(order, token)
            AppStore->>DSP: authorizePayment(order, token, "mock-face-assertion")
            activate DSP
            DSP-->>AppStore: DSPPaymentAuthorization(decision: .approved, riskScore: 18)
            deactivate DSP
            AppStore->>PaymentSvc: pay(order, token)
            activate PaymentSvc
            PaymentSvc-->>AppStore: PaymentReceipt
            deactivate PaymentSvc
            AppStore->>AppStore: order.status = .paid
            AppStore-->>ChatView: Append ReceiptCard attachment
            deactivate AppStore
        end
    end
```

---

## Sequence Diagram: Wealth A2UI Cards

```mermaid
sequenceDiagram
    autonumber
    actor User as 👤 User
    participant ChatView as ChatView
    participant AppStore as AppStore
    participant MCP as ⚙️ HSBC MCP Server
    participant A2UI as A2UI Renderer

    rect rgb(240, 249, 255)
        Note over User,A2UI: 📊 Portfolio card after HSBC consent
        User->>ChatView: "What is my profollio?"
        activate ChatView
        ChatView->>AppStore: send(.sendMessage)
        deactivate ChatView
        activate AppStore
        AppStore->>AppStore: routeUserMessage → showPortfolio
        AppStore->>MCP: hsbc_get_portfolio_summary(consentId)
        activate MCP
        MCP-->>AppStore: a2ui.component = portfolioSummary
        deactivate MCP
        AppStore-->>ChatView: Append PortfolioSummaryCard attachment
        deactivate AppStore
        ChatView->>A2UI: Render portfolio pie + category values
    end

    rect rgb(236, 253, 245)
        Note over User,A2UI: 📈 Fund ranking card in chat
        User->>ChatView: "What are my top funds?"
        activate ChatView
        ChatView->>AppStore: send(.sendMessage)
        deactivate ChatView
        activate AppStore
        AppStore->>AppStore: routeUserMessage → showTopFunds
        AppStore->>MCP: hsbc_get_top_funds(consentId)
        activate MCP
        MCP-->>AppStore: a2ui.component = topFunds
        deactivate MCP
        AppStore-->>ChatView: Append TopFundsCard attachment
        deactivate AppStore
        ChatView->>A2UI: Render tabs + fund rows
    end

    User->>ChatView: "It is great, I want to drink one coffee"
    ChatView->>AppStore: send(.startCoffeeJourney)
```

---

## Sequence Diagram: Future MCP Tool Orchestration

```mermaid
sequenceDiagram
    autonumber
    actor User as 👤 User
    participant ChatGPTCoffee as ChatGPTCoffee Runtime
    participant MCP as ⚙️ HSBC MCP Server
    participant Commerce as 🛍️ Commerce / Travel API
    participant OpenBanking as 🏦 HSBC Open Banking API
    participant DSP as 🛡️ HSBC DSP Agent

    User->>ChatGPTCoffee: Wealth, shopping, or travel request
    activate ChatGPTCoffee
    ChatGPTCoffee->>MCP: Read scenario routing + available tools
    activate MCP
    MCP-->>ChatGPTCoffee: Tool catalog + routing rules
    deactivate MCP

    alt 🔗 Bind HSBC account
        rect rgb(254, 242, 242)
            ChatGPTCoffee->>MCP: hsbc_create_consent_link
            activate MCP
            MCP->>OpenBanking: POST /consents
            activate OpenBanking
            OpenBanking-->>MCP: consentId + authorizationUrl
            deactivate OpenBanking
            MCP-->>ChatGPTCoffee: bind link / card data
            deactivate MCP
            ChatGPTCoffee-->>User: Show bind HSBC card
        end
    else 📊 Wealth A2UI request
        rect rgb(240, 249, 255)
            ChatGPTCoffee->>MCP: hsbc_get_portfolio_summary / hsbc_get_top_funds
            activate MCP
            MCP->>OpenBanking: Read consent-scoped wealth data
            activate OpenBanking
            OpenBanking-->>MCP: holdings / fund rankings
            deactivate OpenBanking
            MCP-->>ChatGPTCoffee: a2ui component payload
            deactivate MCP
            ChatGPTCoffee-->>User: Render portfolio or top funds in chat
        end
    else ☕ Coffee request
        rect rgb(236, 253, 245)
            ChatGPTCoffee->>MCP: commerce_search_coffee
            activate MCP
            MCP->>Commerce: Search nearby coffee shops
            activate Commerce
            Commerce-->>MCP: coffee shops and menus
            deactivate Commerce
            MCP-->>ChatGPTCoffee: coffee results
            deactivate MCP
            ChatGPTCoffee-->>User: Show shop / menu cards
            User->>ChatGPTCoffee: Select item and order
            ChatGPTCoffee->>MCP: commerce_create_coffee_order
            activate MCP
            MCP->>Commerce: Create unpaid order
            activate Commerce
            Commerce-->>MCP: orderId, merchantId, amount
            deactivate Commerce
            MCP-->>ChatGPTCoffee: unpaid order
            deactivate MCP
        end
    else 🏨✈️ Hotel or flight request
        rect rgb(240, 249, 255)
            ChatGPTCoffee->>MCP: travel_search_hotels / travel_search_flights
            activate MCP
            MCP->>Commerce: Search travel inventory
            activate Commerce
            Commerce-->>MCP: options
            deactivate Commerce
            MCP-->>ChatGPTCoffee: options
            deactivate MCP
            ChatGPTCoffee-->>User: Show options
            User->>ChatGPTCoffee: Select booking
            ChatGPTCoffee->>MCP: travel_create_hotel_booking / travel_create_flight_booking
            activate MCP
            MCP->>Commerce: Create unpaid booking
            activate Commerce
            Commerce-->>MCP: booking / order data
            deactivate Commerce
            MCP-->>ChatGPTCoffee: unpaid booking
            deactivate MCP
        end
    end

    rect rgb(255, 251, 235)
        Note over User,DSP: 💳 Payment authorization (all journeys)
        ChatGPTCoffee-->>User: Show visible order / booking summary
        User->>ChatGPTCoffee: Confirm payment
        ChatGPTCoffee->>MCP: hsbc_create_payment_quote
        activate MCP
        MCP->>OpenBanking: POST /payment-quotes
        activate OpenBanking
        OpenBanking-->>MCP: quoteId + riskDecision
        deactivate OpenBanking
        MCP-->>ChatGPTCoffee: payment quote
        deactivate MCP
        ChatGPTCoffee-->>User: Facial verification challenge
        User->>ChatGPTCoffee: Complete facial verification
        ChatGPTCoffee->>MCP: hsbc_dsp_authorize_payment
        activate MCP
        MCP->>DSP: Authorize quote + consent + biometric assertion
        activate DSP
        DSP-->>MCP: approved dspAuthorizationId
        deactivate DSP
        MCP-->>ChatGPTCoffee: DSP authorization result
        deactivate MCP
        ChatGPTCoffee->>MCP: hsbc_submit_payment
        activate MCP
        MCP->>OpenBanking: POST /payments (dspAuthorizationId)
        activate OpenBanking
        OpenBanking-->>MCP: payment receipt
        deactivate OpenBanking
        MCP-->>ChatGPTCoffee: payment receipt
        deactivate MCP
        ChatGPTCoffee-->>User: Show receipt in chat
    end
    deactivate ChatGPTCoffee
```
