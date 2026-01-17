import Foundation
import CoreGraphics

/// Validates spatial relationships between detected objects
///
/// Checks if toothbrush bounding box is appropriately positioned
/// relative to the mouth region
final class SpatialValidator {

    // MARK: - Configuration

    /// How much to expand the mouth bounds for overlap detection
    /// This accounts for toothbrush extending slightly outside mouth
    private let mouthExpansionFactor: CGFloat = 1.5

    /// Minimum overlap ratio required (intersection / toothbrush area)
    private let minimumOverlapRatio: CGFloat = 0.1

    /// Maximum allowed vertical distance from mouth center
    /// as a ratio of face height
    private let maxVerticalDistanceRatio: CGFloat = 0.3

    // MARK: - Validation

    /// Check if toothbrush is positioned at/near the mouth
    func isToothbrushAtMouth(
        toothbrushBounds: CGRect,
        mouthBounds: CGRect,
        imageSize: CGSize
    ) -> Bool {
        // Expand mouth bounds to be more lenient
        let expandedMouth = expandRect(mouthBounds, factor: mouthExpansionFactor)

        // Check for intersection
        if toothbrushBounds.intersects(expandedMouth) {
            let intersection = toothbrushBounds.intersection(expandedMouth)
            let overlapRatio = intersection.area / toothbrushBounds.area

            if overlapRatio >= minimumOverlapRatio {
                return true
            }
        }

        // Fallback: check if toothbrush center is near mouth center
        let toothbrushCenter = toothbrushBounds.center
        let mouthCenter = mouthBounds.center

        let verticalDistance = abs(toothbrushCenter.y - mouthCenter.y)
        let horizontalDistance = abs(toothbrushCenter.x - mouthCenter.x)

        // Toothbrush should be within reasonable distance of mouth
        let maxVerticalDistance = mouthBounds.height * 2
        let maxHorizontalDistance = mouthBounds.width * 1.5

        return verticalDistance < maxVerticalDistance &&
               horizontalDistance < maxHorizontalDistance
    }

    /// Calculate a confidence score for the spatial relationship
    func calculateSpatialConfidence(
        toothbrushBounds: CGRect,
        mouthBounds: CGRect
    ) -> Float {
        let expandedMouth = expandRect(mouthBounds, factor: mouthExpansionFactor)

        if toothbrushBounds.intersects(expandedMouth) {
            let intersection = toothbrushBounds.intersection(expandedMouth)
            let overlapRatio = intersection.area / toothbrushBounds.area
            return Float(min(1.0, overlapRatio * 2))
        }

        // Calculate distance-based confidence
        let toothbrushCenter = toothbrushBounds.center
        let mouthCenter = mouthBounds.center
        let distance = sqrt(
            pow(toothbrushCenter.x - mouthCenter.x, 2) +
            pow(toothbrushCenter.y - mouthCenter.y, 2)
        )

        let maxDistance = mouthBounds.width * 3
        let confidence = max(0, 1 - (distance / maxDistance))

        return Float(confidence)
    }

    // MARK: - Helpers

    private func expandRect(_ rect: CGRect, factor: CGFloat) -> CGRect {
        let expandX = rect.width * (factor - 1) / 2
        let expandY = rect.height * (factor - 1) / 2

        return CGRect(
            x: rect.origin.x - expandX,
            y: rect.origin.y - expandY,
            width: rect.width * factor,
            height: rect.height * factor
        )
    }
}

// MARK: - CGRect Extensions

private extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }

    var area: CGFloat {
        width * height
    }
}
