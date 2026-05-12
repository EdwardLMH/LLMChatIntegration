import Foundation

public protocol WeatherServicing {
    func currentWeatherSummary() async throws -> String
}

public struct MockWeatherService: WeatherServicing {
    public init() {}

    public func currentWeatherSummary() async throws -> String {
        "Cool and cloudy, 18C"
    }
}
