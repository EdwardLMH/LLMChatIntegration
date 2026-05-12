# LLM Chat Integration iOS Prototype

This workspace contains two separate iOS apps plus one shared Swift package:

- `ChatGPTCoffeeApp/`: ChatGPT-like app that starts HSBC consent and later pays for coffee.
- `HSBCBankingMockApp/`: HSBC Mobile Banking mock that approves consent and issues a mock OAuth token.
- `SharedOpenBankingKit/`: shared Swift package used by both apps.

## Open In Xcode

Open the workspace, not only one app project:

```text
LLMChatIntegration.xcworkspace
```

The workspace includes both apps and the local shared package, so Xcode can resolve:

```swift
import SharedOpenBankingKit
```

## Run Order

1. Select the `HSBCBankingMockApp` scheme and run it once in the simulator.
2. Select the `ChatGPTCoffeeApp` scheme and run it.
3. In chat, type `I want to bind my HSBC account`.
4. Tap `Open HSBC`.
5. Approve consent in the banking app.
6. Return to chat and type `I am tired, I want coffee`.
