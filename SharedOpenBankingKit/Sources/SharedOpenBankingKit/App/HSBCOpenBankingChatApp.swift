import SwiftUI

public struct HSBCOpenBankingChatDemoRoot: View {
    @StateObject private var store: AppStore

    public init(environment: AppEnvironment = .preview) {
        _store = StateObject(wrappedValue: AppStore(initialState: AppState(), environment: environment))
    }

    public var body: some View {
        RootView()
            .environmentObject(store)
    }
}

public typealias ChatGPTLikeDemoRoot = HSBCOpenBankingChatDemoRoot
