import Foundation
import LocalAuthentication

public protocol BiometricAuthorizing {
    func verifyFace(reason: String) async -> Bool
}

public struct LocalBiometricAuthorizer: BiometricAuthorizing {
    public init() {}

    public func verifyFace(reason: String) async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }

        return await withCheckedContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
                continuation.resume(returning: success)
            }
        }
    }
}
