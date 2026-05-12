# Scenario Routing Rules

These rules describe how ChatGPT should decide which MCP tools to call. HSBC developers provide this MCP layer so ChatGPT can map user intent to Open Banking, commerce, travel, and HSBC DSP Authorization Agent APIs.

## Consent Journey

Trigger examples:

- "I want to bind HSBC."
- "Connect my HSBC account."
- "Use HSBC for payment."

Tool:

1. `hsbc_create_consent_link`

Assistant behavior:

- Explain that HSBC will handle authentication and consent.
- Show the authorization link/card.
- Do not claim payment is possible until a valid token/consent exists.

## Coffee Journey

Trigger examples:

- "I am tired, I want coffee."
- "Find nearby Starbucks."
- "Order Luckin coffee."

Tool flow:

1. `commerce_search_coffee`
2. User selects shop and item.
3. `commerce_create_coffee_order`
4. Assistant shows an order card with Pay button.
5. User types "confirm" or presses Pay.
6. `hsbc_create_payment_quote`
7. Run biometric verification in the trusted client boundary.
8. `hsbc_dsp_authorize_payment`
9. `hsbc_submit_payment`

## Hotel Journey

Trigger examples:

- "Book a hotel in Hong Kong tomorrow."
- "Find a room near Central for two nights."

Tool flow:

1. `travel_search_hotels`
2. User selects hotel and room.
3. `travel_create_hotel_booking`
4. `hsbc_create_payment_quote`
5. Explicit user confirmation.
6. Biometric verification.
7. `hsbc_dsp_authorize_payment`
8. `hsbc_submit_payment`

## Flight Journey

Trigger examples:

- "Book a flight from Shanghai to Singapore next Friday."
- "Find a return ticket to London."

Tool flow:

1. `travel_search_flights`
2. User selects itinerary.
3. `travel_create_flight_booking`
4. `hsbc_create_payment_quote`
5. Explicit user confirmation.
6. Biometric verification.
7. `hsbc_dsp_authorize_payment`
8. `hsbc_submit_payment`

## DSP Authorization Agent

`hsbc_dsp_authorize_payment` represents HSBC Digital Security Platform as a payment authorization agent. ChatGPT calls it through MCP after the user confirms the visible order or booking summary.

DSP responsibilities:

- Validate that the OAuth consent covers the merchant category and payment type.
- Check payment risk against quote, amount, merchant, device, and session context.
- Require facial verification when the risk policy demands step-up authentication.
- Return a `dspAuthorizationId` that binds the user confirmation, biometric assertion, and payment quote.

Open Banking payment submission must use the `dspAuthorizationId`. ChatGPT should not treat the OAuth token alone as permission to complete a payment.

## Safety Rules

- Never submit payment based only on inferred intent.
- Require a visible order or booking summary before payment.
- Require explicit confirmation, such as "confirm", "pay", or tapping a Pay button.
- Require biometric verification before `hsbc_dsp_authorize_payment` when DSP requests step-up.
- Require a DSP authorization reference before `hsbc_submit_payment`.
- If HSBC consent is missing or expired, call `hsbc_create_consent_link` first.
