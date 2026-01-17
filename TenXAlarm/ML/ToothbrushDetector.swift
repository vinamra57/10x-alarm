import Foundation
import Vision
import CoreML
import UIKit

/// Toothbrush detection using YOLO/Core ML
///
/// Uses YOLOv8 pre-trained on COCO dataset (toothbrush is class 79)
final class ToothbrushDetector {

    // MARK: - Output Types

    struct DetectionResult {
        /// Bounding box in image coordinates
        let bounds: CGRect

        /// Detection confidence (0-1)
        let confidence: Float

        /// Class label (should be "toothbrush")
        let label: String
    }

    // MARK: - Configuration

    /// Minimum confidence threshold for detection
    private let confidenceThreshold: Float = 0.3

    /// IoU threshold for non-max suppression
    private let iouThreshold: Float = 0.5

    /// COCO class index for toothbrush
    private let toothbrushClassIndex = 79

    // MARK: - Model

    private var model: VNCoreMLModel?

    init() {
        loadModel()
    }

    private func loadModel() {
        // Load the YOLOv8n CoreML model
        // The model detects 80 COCO classes including toothbrush (class 79)
        do {
            // Try loading compiled model first (faster)
            if let modelURL = Bundle.main.url(forResource: "yolov8n", withExtension: "mlmodelc") {
                let mlModel = try MLModel(contentsOf: modelURL)
                self.model = try VNCoreMLModel(for: mlModel)
                print("ToothbrushDetector: Loaded compiled model")
                return
            }

            // Fall back to mlpackage
            if let modelURL = Bundle.main.url(forResource: "yolov8n", withExtension: "mlpackage") {
                let mlModel = try MLModel(contentsOf: modelURL)
                self.model = try VNCoreMLModel(for: mlModel)
                print("ToothbrushDetector: Loaded mlpackage model")
                return
            }

            print("ToothbrushDetector: Model file not found in bundle")
        } catch {
            print("ToothbrushDetector: Failed to load model - \(error.localizedDescription)")
        }
    }

    // MARK: - Detection

    /// Detect toothbrush in image
    func detect(in image: UIImage) async -> DetectionResult? {
        guard let cgImage = image.cgImage else { return nil }

        // If model isn't loaded, use fallback detection
        guard let model = model else {
            return await fallbackDetection(in: image)
        }

        return await withCheckedContinuation { continuation in
            let request = VNCoreMLRequest(model: model) { request, error in
                guard error == nil,
                      let results = request.results as? [VNRecognizedObjectObservation] else {
                    continuation.resume(returning: nil)
                    return
                }

                // Find toothbrush detections
                let toothbrushDetections = results.filter { observation in
                    guard let topLabel = observation.labels.first else { return false }
                    return topLabel.identifier.lowercased().contains("toothbrush") &&
                           topLabel.confidence >= self.confidenceThreshold
                }

                // Return highest confidence detection
                guard let best = toothbrushDetections.max(by: { $0.confidence < $1.confidence }) else {
                    continuation.resume(returning: nil)
                    return
                }

                let bounds = VNImageRectForNormalizedRect(
                    best.boundingBox,
                    Int(image.size.width),
                    Int(image.size.height)
                )

                let result = DetectionResult(
                    bounds: bounds,
                    confidence: best.confidence,
                    label: "toothbrush"
                )

                continuation.resume(returning: result)
            }

            request.imageCropAndScaleOption = .scaleFill

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }

    // MARK: - Fallback Detection

    /// Fallback detection using object recognition
    /// Used when YOLO model isn't available
    private func fallbackDetection(in image: UIImage) async -> DetectionResult? {
        guard let cgImage = image.cgImage else { return nil }

        return await withCheckedContinuation { continuation in
            // Use Vision's built-in object recognition
            let request = VNRecognizeAnimalsRequest { request, error in
                // This won't detect toothbrushes, but serves as a placeholder
                // In production, the YOLO model should be used
                continuation.resume(returning: nil)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }

    // MARK: - Model Loading Utilities

    /// Check if model is loaded and ready
    var isModelLoaded: Bool {
        model != nil
    }

    /// Reload model (useful after app update)
    func reloadModel() {
        loadModel()
    }
}

// MARK: - COCO Class Labels (for reference)

extension ToothbrushDetector {
    /// COCO dataset class labels
    /// Toothbrush is at index 79
    static let cocoClasses = [
        "person", "bicycle", "car", "motorcycle", "airplane", "bus", "train", "truck",
        "boat", "traffic light", "fire hydrant", "stop sign", "parking meter", "bench",
        "bird", "cat", "dog", "horse", "sheep", "cow", "elephant", "bear", "zebra",
        "giraffe", "backpack", "umbrella", "handbag", "tie", "suitcase", "frisbee",
        "skis", "snowboard", "sports ball", "kite", "baseball bat", "baseball glove",
        "skateboard", "surfboard", "tennis racket", "bottle", "wine glass", "cup",
        "fork", "knife", "spoon", "bowl", "banana", "apple", "sandwich", "orange",
        "broccoli", "carrot", "hot dog", "pizza", "donut", "cake", "chair", "couch",
        "potted plant", "bed", "dining table", "toilet", "tv", "laptop", "mouse",
        "remote", "keyboard", "cell phone", "microwave", "oven", "toaster", "sink",
        "refrigerator", "book", "clock", "vase", "scissors", "teddy bear", "hair drier",
        "toothbrush" // Index 79
    ]
}
