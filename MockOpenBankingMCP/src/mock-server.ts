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

  async hsbc_get_portfolio_summary(input) {
    return {
      consentId: input.consentId,
      a2ui: {
        component: "portfolioSummary",
        version: "1.0",
        props: {
          currencyCode: "CNY",
          totalValue: 301790.50,
          categories: [
            { name: "Funds&Related", percentage: 62.51, value: 188640.50, colorHex: "#D63622" },
            { name: "AMP&Trust", percentage: 4.24, value: 12780.00, colorHex: "#E34B38" },
            { name: "WMP", percentage: 2.76, value: 8340.00, colorHex: "#FF6F59" },
            { name: "QDII Bond", percentage: 1.74, value: 5240.00, colorHex: "#F3B7AE" },
            { name: "QDII Structured Note", percentage: 1.21, value: 3650.00, colorHex: "#4C474A" },
            { name: "Structured Deposits", percentage: 3.73, value: 11250.00, colorHex: "#6D686B" },
            { name: "Insurance", percentage: 9.71, value: 29300.00, colorHex: "#AAA5A8" },
            { name: "Cash/Deposits", percentage: 14.11, value: 42590.00, colorHex: "#E3DFE0" }
          ]
        }
      }
    };
  },

  async hsbc_get_top_funds(input) {
    return {
      consentId: input.consentId,
      a2ui: {
        component: "topFunds",
        version: "1.0",
        props: {
          title: "Top 3 funds",
          funds: [
            {
              name: "AB SICAV I - LOW VOLATILITY EQUITY PORTFOLIO CLASS AD S...",
              code: "U43120",
              oneYearReturn: 54.79
            },
            {
              name: "HANG SENG INDEX FUND CLASS A (HKD)",
              code: "U42272",
              badge: "ESG",
              oneYearReturn: 18.10
            },
            {
              name: "ALLIANZ INCOME AND GROWTH CLASS AM DIS (HKD MONTHLY...",
              code: "U40032",
              badge: "New fund",
              oneYearReturn: 11.45
            }
          ]
        }
      }
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
