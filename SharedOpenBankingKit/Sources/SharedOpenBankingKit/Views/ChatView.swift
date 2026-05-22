import SwiftUI

struct ChatView: View {
    @EnvironmentObject private var store: AppStore
    @State private var input = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(store.state.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                    }
                    .onChange(of: store.state.messages.count) { _, _ in
                        guard let last = store.state.messages.last else { return }
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }

                ChatInputBar(
                    text: $input,
                    isInputFocused: $isInputFocused,
                    onSend: sendCurrentMessage
                )
            }
            .navigationTitle("ChatGPTCoffee x HSBC")
            .toolbarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .top) {
                JourneyStatusBar()
            }
        }
    }

    private func sendCurrentMessage() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        input = ""
        isInputFocused = false
        store.send(.sendMessage(text))
    }
}

private struct JourneyStatusBar: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        HStack(spacing: 8) {
            Label(consentText, systemImage: consentIcon)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(consentColor)
            Spacer()
            if store.state.isLoading {
                ProgressView()
                    .scaleEffect(0.75)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.white)
    }

    private var consentText: String {
        if case let .connected(token) = store.state.consentStatus {
            return "HSBC ****\(token.accountMask)"
        }
        return "HSBC not bound"
    }

    private var consentIcon: String {
        if case .connected = store.state.consentStatus {
            return "checkmark.shield.fill"
        }
        return "shield"
    }

    private var consentColor: Color {
        if case .connected = store.state.consentStatus {
            return .green
        }
        return AppTheme.muted
    }
}

private struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
            Text(message.text)
                .font(.body)
                .foregroundStyle(message.role == .user ? .white : AppTheme.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(message.role == .user ? AppTheme.ink : AppTheme.panel)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            if let attachment = message.attachment {
                AttachmentView(attachment: attachment)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
    }
}

private struct AttachmentView: View {
    let attachment: ChatAttachment

    var body: some View {
        switch attachment {
        case let .bindHSBCCard(request):
            BindHSBCCard(request: request)
        case let .portfolioSummary(portfolio):
            PortfolioSummaryCard(portfolio: portfolio)
        case let .topFunds(funds):
            TopFundsCard(fundsList: funds)
        case let .shopCarousel(shops):
            ShopCarousel(shops: shops)
        case let .orderCard(order):
            OrderCard(order: order)
        case let .paymentReceipt(receipt):
            ReceiptCard(receipt: receipt)
        }
    }
}

private struct ChatInputBar: View {
    @Binding var text: String
    let isInputFocused: FocusState<Bool>.Binding
    let onSend: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            TextField("Message", text: $text, axis: .vertical)
                .focused(isInputFocused)
                .submitLabel(.send)
                .onSubmit(onSend)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Button(action: onSend) {
                Image(systemName: "arrow.up")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(AppTheme.hsbcRed)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Send")
        }
        .padding(12)
        .background(AppTheme.paper)
    }
}
