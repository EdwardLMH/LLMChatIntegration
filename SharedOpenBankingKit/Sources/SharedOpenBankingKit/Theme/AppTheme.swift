import SwiftUI

enum AppTheme {
    static let hsbcRed = Color(red: 219 / 255, green: 0, blue: 17 / 255)
    static let ink = Color(red: 25 / 255, green: 28 / 255, blue: 34 / 255)
    static let paper = Color(red: 247 / 255, green: 248 / 255, blue: 250 / 255)
    static let panel = Color.white
    static let muted = Color(red: 103 / 255, green: 112 / 255, blue: 124 / 255)
}

extension Decimal {
    var moneyText: String {
        let number = self as NSDecimalNumber
        return NumberFormatter.money.string(from: number) ?? "\(number)"
    }
}

extension NumberFormatter {
    static let money: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CNY"
        formatter.maximumFractionDigits = 2
        return formatter
    }()
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let red = Double((int >> 16) & 0xff) / 255
        let green = Double((int >> 8) & 0xff) / 255
        let blue = Double(int & 0xff) / 255
        self.init(red: red, green: green, blue: blue)
    }
}
