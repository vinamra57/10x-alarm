import Foundation
import Vision
import UIKit

/// Face detection and landmark extraction using Vision framework
final class FaceAnalyzer {

    // MARK: - Output Types

    struct FaceResult {
        /// Bounding box in image coordinates
        let bounds: CGRect

        /// Mouth region bounds (if available)
        let mouthBounds: CGRect?

        /// Detection confidence (0-1)
        let confidence: Float

        /// All facial landmarks
        let landmarks: VNFaceLandmarks2D?
    }

    // MARK: - Detection

    /// Detect the primary face in an image
    func detectFace(in image: UIImage) async -> FaceResult? {
        guard let cgImage = image.cgImage else { return nil }

        return await withCheckedContinuation { continuation in
            let request = VNDetectFaceLandmarksRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNFaceObservation],
                      let face = observations.first else {
                    continuation.resume(returning: nil)
                    return
                }

                let result = self.processObservation(face, imageSize: image.size)
                continuation.resume(returning: result)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }

    /// Detect all faces in an image
    func detectAllFaces(in image: UIImage) async -> [FaceResult] {
        guard let cgImage = image.cgImage else { return [] }

        return await withCheckedContinuation { continuation in
            let request = VNDetectFaceLandmarksRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNFaceObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let results = observations.map {
                    self.processObservation($0, imageSize: image.size)
                }
                continuation.resume(returning: results)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: [])
            }
        }
    }

    // MARK: - Processing

    private func processObservation(_ observation: VNFaceObservation, imageSize: CGSize) -> FaceResult {
        // Convert normalized bounds to image coordinates
        let bounds = VNImageRectForNormalizedRect(
            observation.boundingBox,
            Int(imageSize.width),
            Int(imageSize.height)
        )

        // Extract mouth bounds from landmarks
        var mouthBounds: CGRect?

        if let landmarks = observation.landmarks,
           let outerLips = landmarks.outerLips {
            mouthBounds = calculateMouthBounds(
                from: outerLips,
                faceBounds: observation.boundingBox,
                imageSize: imageSize
            )
        }

        return FaceResult(
            bounds: bounds,
            mouthBounds: mouthBounds,
            confidence: observation.confidence,
            landmarks: observation.landmarks
        )
    }

    private func calculateMouthBounds(
        from region: VNFaceLandmarkRegion2D,
        faceBounds: CGRect,
        imageSize: CGSize
    ) -> CGRect {
        let points = region.normalizedPoints

        guard !points.isEmpty else {
            // Fallback: estimate mouth as lower third of face
            return CGRect(
                x: faceBounds.origin.x * imageSize.width,
                y: faceBounds.origin.y * imageSize.height,
                width: faceBounds.width * imageSize.width,
                height: faceBounds.height * imageSize.height * 0.3
            )
        }

        // Find bounding box of mouth points
        var minX: CGFloat = .infinity
        var maxX: CGFloat = -.infinity
        var minY: CGFloat = .infinity
        var maxY: CGFloat = -.infinity

        for point in points {
            // Points are relative to face bounding box
            let absoluteX = (faceBounds.origin.x + point.x * faceBounds.width) * imageSize.width
            let absoluteY = (faceBounds.origin.y + point.y * faceBounds.height) * imageSize.height

            minX = min(minX, absoluteX)
            maxX = max(maxX, absoluteX)
            minY = min(minY, absoluteY)
            maxY = max(maxY, absoluteY)
        }

        // Add padding around mouth
        let padding: CGFloat = 20
        return CGRect(
            x: minX - padding,
            y: minY - padding,
            width: (maxX - minX) + padding * 2,
            height: (maxY - minY) + padding * 2
        )
    }
}
