# HSBC Open Banking Two-App iOS Prototype

Native SwiftUI scaffold for two apps and two ChatGPT-led journeys:

1. In the ChatGPT-like app, bind an HSBC account from chat, deep-link to HSBC Mobile Banking, complete facial recognition, grant Open Banking consent, and receive an OAuth token callback.
2. Ask for coffee in chat, browse nearby shops, create an order card, confirm payment, verify face, and pay through HSBC with the prior consent token.

## Project Shape

- `../ChatGPTCoffeeApp/`: standalone Xcode iOS app project for the ChatGPT-like chat client.
- `../HSBCBankingMockApp/`: standalone Xcode iOS app project for the HSBC Mobile Banking mock.
- `../SharedOpenBankingKit/`: shared Swift package imported by both apps.
- `Sources/SharedOpenBankingKit/Models/DomainModels.swift`: consent, OAuth token, coffee shop, order, receipt, and chat attachment models.
- `Redux/`: ChatGPT-like app state, actions, reducer/store, and service dependencies.
- `BankingApp/`: HSBC mock banking app state, reducer/store, consent review UI, face verification, and OAuth callback.
- `Routing/AppURLRouter.swift`: app-to-app URL contract for `hsbc-mobile://...` consent requests and `chatgpt://...` token callbacks.
- `Services/`: mocked HSBC consent, OAuth token issuance, merchant discovery, weather, payment, and biometric boundaries.
- `Views/`: native SwiftUI chat UI, HSBC binding card, shop carousel, order card, facial verification sheet, and receipt card.

## How To Use In Xcode

Open the generated workspace from the repository root:

```text
../LLMChatIntegration.xcworkspace
```

Both projects reference this shared package through a local package dependency:

```text
../SharedOpenBankingKit
```

For the ChatGPT-like target:

```swift
ChatGPTLikeDemoRoot(environment: .preview)
```

Register this target for the callback URL scheme:

```text
chatgpt://hsbc/consent-callback
```

For the HSBC mock banking target:

```swift
HSBCBankingDemoRoot(environment: .preview)
```

Register this target for the consent URL scheme:

```text
hsbc-mobile://open-banking/consent
```

Replace `.preview` with real service implementations when HSBC Open Banking, MCP, merchant, and weather APIs are ready.

## Run Order

1. Run `HSBCBankingMockApp` once in the simulator so iOS installs the `hsbc-mobile` URL scheme handler.
2. Run `ChatGPTCoffeeApp`.
3. In chat, type `I want to bind my HSBC account`.
4. Tap `Open HSBC`, approve consent in the banking mock, and return through the token callback.
5. In chat, type `I am tired, I want coffee`, then order and pay.

## Integration Notes

- The ChatGPT-like app creates a `ConsentRequest`, opens `request.redirectURL`, and waits for `chatgpt://hsbc/consent-callback`.
- The HSBC mock app parses the incoming consent link, shows scopes, simulates facial recognition, issues an `OAuthToken`, and opens the callback URL.
- The HSBC OAuth access token is modeled in `OAuthToken`, but real storage should use Keychain and server-side token exchange.
- The production consent journey should prefer universal links and OAuth authorization code + PKCE. This mock uses custom schemes for local prototyping.
- `LocalBiometricAuthorizer` wraps iOS `LocalAuthentication`; in production the HSBC or trusted payment boundary should own biometric policy and risk checks.
- The mock payment service only proves state flow. A real implementation should call the HSBC payment orchestration endpoint with consent ID, payment quote, idempotency key, merchant order ID, amount, currency, and risk context.
