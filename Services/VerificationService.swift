import Foundation
import UIKit
import SwiftData

/// Service for coordinating the ML verification pipeline
///
/// Pipeline:
/// 1. Face + Mouth Detection (Vision framework)
/// 2. Toothbrush Detection (YOLO/Core ML)
/// 3. Spatial Relationship Check (geometry)
@Observable
final class VerificationService {
    private let modelContext: ModelContext
    private let faceAnalyzer: FaceAnalyzer
    private let toothbrushDetector: ToothbrushDetector
    private let spatialValidator: SpatialValidator

    /// Minimum required face size as percentage of image
    private let minimumFaceSize: CGFloat = 0.15

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.faceAnalyzer = FaceAnalyzer()
        self.toothbrushDetector = ToothbrushDetector()
        self.spatialValidator = SpatialValidator()
    }

    // MARK: - Main Verification

    /// Verify that the image shows someone actively brushing their teeth
    func verify(image: UIImage) async -> VerificationOutput { // swiftlint:disable:this function_body_length
        // Step 1: Face Detection
        guard let faceResult = await faceAnalyzer.detectFace(in: image) else {
            return VerificationOutput(
                passed: false,
                reason: .noFaceDetected,
                confidence: 0
            )
        }

        // Check face size
        let imageSize = image.size
        let faceArea = faceResult.bounds.width * faceResult.bounds.height
        let imageArea = imageSize.width * imageSize.height
        let faceRatio = faceArea / imageArea

        if faceRatio < minimumFaceSize {
            return VerificationOutput(
                passed: false,
                reason: .faceTooSmall,
                confidence: 0
            )
        }

        // Check for multiple faces
        let allFaces = await faceAnalyzer.detectAllFaces(in: image)
        if allFaces.count > 1 {
            return VerificationOutput(
                passed: false,
                reason: .multipleFaces,
                confidence: 0
            )
        }

        // Step 2: Toothbrush Detection
        guard let toothbrushResult = await toothbrushDetector.detect(in: image) else {
            return VerificationOutput(
                passed: false,
                reason: .noToothbrushDetected,
                confidence: 0
            )
        }

        // Step 3: Spatial Relationship
        guard let mouthBounds = faceResult.mouthBounds else {
            return VerificationOutput(
                passed: false,
                reason: .noFaceDetected,
                confidence: 0
            )
        }

        let isAtMouth = spatialValidator.isToothbrushAtMouth(
            toothbrushBounds: toothbrushResult.bounds,
            mouthBounds: mouthBounds,
            imageSize: imageSize
        )

        if !isAtMouth {
            return VerificationOutput(
                passed: false,
                reason: .toothbrushNotAtMouth,
                confidence: toothbrushResult.confidence
            )
        }

        // All checks passed!
        let overallConfidence = min(faceResult.confidence, toothbrushResult.confidence)

        return VerificationOutput(
            passed: true,
            reason: nil,
            confidence: overallConfidence
        )
    }

    // MARK: - Recording Results

    /// Record a verification attempt
    func recordVerification(
        result: VerificationOutput,
        wasAlarmDay: Bool,
        attemptCount: Int
    ) throws {
        let verification = Verification(
            wasAlarmDay: wasAlarmDay,
            result: result.passed ? .pass : .fail,
            failureReason: result.reason,
            attemptCount: attemptCount
        )

        modelContext.insert(verification)
        try modelContext.save()
    }
}

// MARK: - Output Types

struct VerificationOutput {
    let passed: Bool
    let reason: VerificationFailureReason?
    let confidence: Float

    var userMessage: String {
        if passed {
            return "Great job! Brush verified."
        }

        switch reason {
        case .noFaceDetected:
            return "Can't see your face. Try better lighting."
        case .noToothbrushDetected:
            return "No toothbrush detected. Make sure it's visible."
        case .toothbrushNotAtMouth:
            return "Put the toothbrush in your mouth and try again."
        case .faceTooSmall:
            return "Move closer to the camera."
        case .multipleFaces:
            return "Only one person should be in frame."
        case .unknown, .none:
            return "Verification failed. Please try again."
        }
    }
}
