import Foundation
import SwiftData

/// Result of a verification attempt
enum VerificationResult: String, Codable {
    case pass
    case fail
}

/// Reason for verification failure
enum VerificationFailureReason: String, Codable {
    case noFaceDetected = "No face detected in photo"
    case noToothbrushDetected = "No toothbrush visible"
    case toothbrushNotAtMouth = "Toothbrush not at mouth"
    case faceTooSmall = "Please move closer to camera"
    case multipleFaces = "Multiple faces detected"
    case unknown = "Verification failed"
}

@Model
final class Verification {
    /// Date/time of verification
    var date: Date

    /// Whether this was an alarm day or voluntary verification
    var wasAlarmDay: Bool

    /// Result of the verification
    var resultRaw: String

    /// Failure reason (if failed)
    var failureReasonRaw: String?

    /// Number of attempts before success (for analytics)
    var attemptCount: Int

    init(
        date: Date = .now,
        wasAlarmDay: Bool,
        result: VerificationResult,
        failureReason: VerificationFailureReason? = nil,
        attemptCount: Int = 1
    ) {
        self.date = date
        self.wasAlarmDay = wasAlarmDay
        self.resultRaw = result.rawValue
        self.failureReasonRaw = failureReason?.rawValue
        self.attemptCount = attemptCount
    }

    var result: VerificationResult {
        get { VerificationResult(rawValue: resultRaw) ?? .fail }
        set { resultRaw = newValue.rawValue }
    }

    var failureReason: VerificationFailureReason? {
        get { failureReasonRaw.flatMap { VerificationFailureReason(rawValue: $0) } }
        set { failureReasonRaw = newValue?.rawValue }
    }

    /// Check if this verification was on the same calendar day as a given date
    func isSameDay(as otherDate: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: otherDate)
    }
}
