import Foundation

public protocol CoffeeServicing {
    func nearbyCoffeeShops() async throws -> [CoffeeShop]
}

public struct MockCoffeeService: CoffeeServicing {
    public init() {}

    public func nearbyCoffeeShops() async throws -> [CoffeeShop] {
        try await Task.sleep(nanoseconds: 350_000_000)
        return SeedData.shops
    }
}
