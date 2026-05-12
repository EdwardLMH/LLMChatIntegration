import SharedOpenBankingKit
import SwiftUI

@main
struct HSBCBankingMockApp: App {
    var body: some Scene {
        WindowGroup {
            HSBCBankingDemoRoot(environment: .preview)
        }
    }
}
