import Foundation

public struct AppEnvironment {
    public let consentService: ConsentServicing
    public let coffeeService: CoffeeServicing
    public let dspAuthorizationService: DSPAuthorizationServicing
    public let paymentService: PaymentServicing
    public let weatherService: WeatherServicing

    public init(
        consentService: ConsentServicing,
        coffeeService: CoffeeServicing,
        dspAuthorizationService: DSPAuthorizationServicing,
        paymentService: PaymentServicing,
        weatherService: WeatherServicing
    ) {
        self.consentService = consentService
        self.coffeeService = coffeeService
        self.dspAuthorizationService = dspAuthorizationService
        self.paymentService = paymentService
        self.weatherService = weatherService
    }

    public static let preview = AppEnvironment(
        consentService: MockConsentService(),
        coffeeService: MockCoffeeService(),
        dspAuthorizationService: MockDSPAuthorizationService(),
        paymentService: MockPaymentService(),
        weatherService: MockWeatherService()
    )
}
