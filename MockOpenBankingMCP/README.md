# Mock HSBC Commerce + DSP MCP Server

This folder defines the backend side of the prototype:

- Mock HSBC Open Banking APIs for consent, token issuance, payment quote, payment submit, and payment status.
- Mock HSBC DSP Authorization Agent APIs for payment risk authorization and biometric step-up.
- Mock commerce/travel APIs for coffee shops, hotel search, flight search, and order creation.
- MCP-style tool definitions provided by HSBC developers that describe when ChatGPT should call each API based on shopping and travel scenarios.
- A small TypeScript service skeleton that can be expanded into a runnable MCP server.

The current iOS apps use local Swift mock services. This backend mock is the next layer: it shows how ChatGPT would reason over scenarios and invoke tools for coffee, hotel, or flight journeys.

## Scenario Routing

| User intent | Tool flow |
| --- | --- |
| "Bind my HSBC account" | `hsbc_create_consent_link` |
| "I am tired, I want coffee" | `commerce_search_coffee` -> `commerce_create_coffee_order` -> `hsbc_create_payment_quote` -> `hsbc_dsp_authorize_payment` -> `hsbc_submit_payment` |
| "Book me a hotel in Shanghai tomorrow" | `travel_search_hotels` -> `travel_create_hotel_booking` -> `hsbc_create_payment_quote` -> `hsbc_dsp_authorize_payment` -> `hsbc_submit_payment` |
| "Find a flight to Singapore next Friday" | `travel_search_flights` -> `travel_create_flight_booking` -> `hsbc_create_payment_quote` -> `hsbc_dsp_authorize_payment` -> `hsbc_submit_payment` |

## Authorization Model

Use **HSBC DSP Authorization Agent via MCP** for payment approval. OAuth consent lets ChatGPT call permitted HSBC APIs; DSP authorization approves one specific payment after user confirmation, risk checks, and facial verification. The Open Banking payment API should receive a DSP authorization reference, not a raw biometric assertion.

## Files

- `openapi/hsbc-openbanking.yaml`: mock HSBC Open Banking API contract.
- `openapi/commerce-travel.yaml`: mock coffee, hotel, and flight API contract.
- `mcp-tools.json`: tool schemas and usage guidance for ChatGPT/MCP, including the HSBC DSP Authorization Agent tool.
- `docs/scenario-routing.md`: prompt/tool decision rules.
- `src/mock-server.ts`: TypeScript skeleton for implementing HTTP/MCP handlers.
- `data/*.json`: deterministic mock data.

## Production Notes

This is intentionally a mock. A real implementation should use OAuth authorization code + PKCE, signed payment requests, idempotency keys, token storage in secure infrastructure, DSP transaction risk controls, consent revocation, audit logging, and human confirmation before any payment.
