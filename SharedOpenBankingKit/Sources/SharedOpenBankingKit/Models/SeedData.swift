import Foundation

enum SeedData {
    static let portfolioSummary = PortfolioSummary(
        currencyCode: "CNY",
        totalValue: 301_790.50,
        categories: [
            PortfolioCategory(name: "Funds&Related", percentage: 62.51, value: 188_640.50, colorHex: "#D63622"),
            PortfolioCategory(name: "AMP&Trust", percentage: 4.24, value: 12_780.00, colorHex: "#E34B38"),
            PortfolioCategory(name: "WMP", percentage: 2.76, value: 8_340.00, colorHex: "#FF6F59"),
            PortfolioCategory(name: "QDII Bond", percentage: 1.74, value: 5_240.00, colorHex: "#F3B7AE"),
            PortfolioCategory(name: "QDII Structured Note", percentage: 1.21, value: 3_650.00, colorHex: "#4C474A"),
            PortfolioCategory(name: "Structured Deposits", percentage: 3.73, value: 11_250.00, colorHex: "#6D686B"),
            PortfolioCategory(name: "Insurance", percentage: 9.71, value: 29_300.00, colorHex: "#AAA5A8"),
            PortfolioCategory(name: "Cash/Deposits", percentage: 14.11, value: 42_590.00, colorHex: "#E3DFE0")
        ]
    )

    static let topFunds = TopFundsList(
        title: "Top 3 funds",
        funds: [
            TopFund(name: "AB SICAV I - LOW VOLATILITY EQUITY PORTFOLIO CLASS AD S...", code: "U43120", badge: nil, oneYearReturn: 54.79),
            TopFund(name: "HANG SENG INDEX FUND CLASS A (HKD)", code: "U42272", badge: "ESG", oneYearReturn: 18.10),
            TopFund(name: "ALLIANZ INCOME AND GROWTH CLASS AM DIS (HKD MONTHLY...", code: "U40032", badge: "New fund", oneYearReturn: 11.45)
        ]
    )

    static let shops: [CoffeeShop] = [
        CoffeeShop(
            name: "Starbucks Reserve",
            distanceMeters: 260,
            rating: 4.7,
            estimatedPickupMinutes: 8,
            brandColorHex: "#006241",
            menu: [
                CoffeeItem(name: "Hot Latte", detail: "Smooth espresso with steamed milk", price: 28, currencyCode: "CNY", caffeineLevel: .medium),
                CoffeeItem(name: "Cold Brew", detail: "Slow-steeped and bright", price: 32, currencyCode: "CNY", caffeineLevel: .high)
            ]
        ),
        CoffeeShop(
            name: "Luckin Coffee",
            distanceMeters: 410,
            rating: 4.6,
            estimatedPickupMinutes: 6,
            brandColorHex: "#21469B",
            menu: [
                CoffeeItem(name: "Coconut Latte", detail: "Light coconut milk with espresso", price: 21, currencyCode: "CNY", caffeineLevel: .medium),
                CoffeeItem(name: "Americano", detail: "Clean espresso over hot water", price: 18, currencyCode: "CNY", caffeineLevel: .high)
            ]
        )
    ]
}
