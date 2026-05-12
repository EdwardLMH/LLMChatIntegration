import SwiftUI

struct BindHSBCCard: View {
    @EnvironmentObject private var store: AppStore
    let request: ConsentRequest

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "banknote")
                    .foregroundStyle(AppTheme.hsbcRed)
                Text("Bind HSBC Account")
                    .font(.headline)
                Spacer()
            }

            Text("Authorize consent in HSBC Mobile Banking using facial recognition.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(request.scopes, id: \.rawValue) { scope in
                    Label(scope.rawValue, systemImage: "checkmark.circle")
                        .font(.caption)
                        .foregroundStyle(AppTheme.ink)
                }
            }

            Button {
                store.send(.openHSBCAppRequested)
            } label: {
                Label("Open HSBC", systemImage: "arrow.up.forward.app")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.hsbcRed)
        }
        .padding(14)
        .frame(maxWidth: 320)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 3)
    }
}

struct FaceVerificationView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(AppTheme.hsbcRed)
                .frame(width: 56, height: 4)

            Image(systemName: "faceid")
                .font(.system(size: 62))
                .foregroundStyle(AppTheme.hsbcRed)

            Text("HSBC Facial Verification")
                .font(.title3.weight(.semibold))

            Text("Verify your face before ChatGPT submits this coffee payment with your HSBC consent token.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppTheme.muted)

            Button {
                store.send(.faceVerificationCompleted(true))
            } label: {
                Label("Verify & Pay", systemImage: "checkmark.shield")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.hsbcRed)

            Button("Cancel") {
                store.send(.dismissFaceVerification)
            }
            .foregroundStyle(AppTheme.muted)
        }
        .padding(24)
    }
}
