import Foundation

enum SeedData {
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
