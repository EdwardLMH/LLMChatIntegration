type ToolResult = Record<string, unknown>;

type ToolHandler = (input: Record<string, unknown>) => Promise<ToolResult>;

const now = () => new Date().toISOString();

const handlers: Record<string, ToolHandler> = {
  async hsbc_create_consent_link(input) {
    const consentId = crypto.randomUUID();
    return {
      consentId,
      authorizationUrl: `hsbc-mobile://open-banking/consent?request_id=${consentId}&client_id=chatgpt-commerce&callback_url=chatgpt://hsbc/consent-callback`,
      scopes: input.requestedScopes,
      expiresAt: new Date(Date.now() + 10 * 60 * 1000).toISOString()
    };
  },

  async commerce_search_coffee(input) {
    return {
      locationHint: input.locationHint,
      weatherSummary: input.weatherSummary,
      results: [
        {
          id: "starbucks-nanjing-rd",
          name: "Starbucks Nanjing Road",
          distanceMeters: 180,
          estimatedPickupMinutes: 8
        },
        {
          id: "luckin-people-square",
          name: "Luckin Coffee People's Square",
          distanceMeters: 260,
          estimatedPickupMinutes: 6
        }
      ]
    };
  },

  async commerce_create_coffee_order(input) {
    return {
      orderId: crypto.randomUUID(),
      merchantId: input.shopId,
      itemId: input.itemId,
      quantity: input.quantity,
      amount: input.itemId === "coconut-latte" ? 19 : 32,
      currencyCode: "CNY",
      status: "awaiting_payment"
    };
  },

  async travel_search_hotels(input) {
    return {
      destination: input.destination,
      checkInDate: input.checkInDate,
      checkOutDate: input.checkOutDate,
      results: [
        {
          id: "hotel-hsbc-bund",
          name: "The Bund Business Hotel",
          fromPrice: 980,
          currencyCode: "CNY"
        }
      ]
    };
  },

  async travel_create_hotel_booking(input) {
    return {
      orderId: crypto.randomUUID(),
      merchantId: input.hotelId,
      roomId: input.roomId,
      amount: 980,
      currencyCode: "CNY",
      status: "awaiting_payment"
    };
  },

  async travel_search_flights(input) {
    return {
      origin: input.origin,
      destination: input.destination,
      departureDate: input.departureDate,
      results: [
        {
          id: "sha-sin-morning",
          departureTime: "09:20",
          arrivalTime: "14:55",
          price: 2680,
          currencyCode: "CNY"
        }
      ]
    };
  },

  async travel_create_flight_booking(input) {
    return {
      orderId: crypto.randomUUID(),
      merchantId: "airline-mock",
      itineraryId: input.itineraryId,
      amount: 2680,
      currencyCode: "CNY",
      status: "awaiting_payment"
    };
  },

  async hsbc_create_payment_quote(input) {
    return {
      quoteId: crypto.randomUUID(),
      orderId: input.orderId,
      amount: input.amount,
      currencyCode: input.currencyCode,
      riskDecision: "allow",
      expiresAt: new Date(Date.now() + 5 * 60 * 1000).toISOString()
    };
  },

  async hsbc_dsp_authorize_payment(input) {
    return {
      dspAuthorizationId: `DSP-${crypto.randomUUID()}`,
      quoteId: input.quoteId,
      orderId: input.orderId,
      decision: "approved",
      riskScore: 18,
      authorizedAt: now(),
      expiresAt: new Date(Date.now() + 3 * 60 * 1000).toISOString()
    };
  },

  async hsbc_submit_payment(input) {
    return {
      paymentId: crypto.randomUUID(),
      quoteId: input.quoteId,
      dspAuthorizationId: input.dspAuthorizationId,
      paymentReference: `HSBC-${Math.floor(Math.random() * 900000 + 100000)}`,
      status: "paid",
      paidAt: now()
    };
  }
};

export async function callTool(name: string, input: Record<string, unknown>): Promise<ToolResult> {
  const handler = handlers[name];
  if (!handler) {
    throw new Error(`Unknown tool: ${name}`);
  }
  return handler(input);
}
