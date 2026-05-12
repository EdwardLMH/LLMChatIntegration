import SwiftUI

public struct RootView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.openURL) private var openURL

    public init() {}

    public var body: some View {
        ChatView()
            .background(AppTheme.paper)
            .sheet(isPresented: Binding(
                get: { store.state.isShowingFaceVerification },
                set: { isPresented in
                    if !isPresented {
                        store.send(.dismissFaceVerification)
                    }
                }
            )) {
                FaceVerificationView()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .alert("Payment issue", isPresented: Binding(
                get: { store.state.errorMessage != nil },
                set: { _ in store.send(.setError(nil)) }
            )) {
                Button("OK", role: .cancel) { store.send(.setError(nil)) }
            } message: {
                Text(store.state.errorMessage ?? "")
            }
            .onOpenURL { url in
                store.send(.handleIncomingURL(url))
            }
            .onChange(of: store.state.hsbcDeepLinkToOpen) { _, url in
                guard let url else { return }
                openURL(url)
            }
    }
}
