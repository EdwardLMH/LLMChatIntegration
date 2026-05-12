import SharedOpenBankingKit
import SwiftUI

@main
struct ChatGPTCoffeeApp: App {
    var body: some Scene {
        WindowGroup {
            ChatGPTLikeDemoRoot(environment: .preview)
        }
    }
}
