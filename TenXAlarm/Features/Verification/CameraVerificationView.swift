import SwiftUI
import AVFoundation

/// Full-screen camera view for verification
struct CameraVerificationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let isAlarmTriggered: Bool

    @State private var capturedImage: UIImage?
    @State private var isProcessing = false
    @State private var verificationResult: VerificationOutput?
    @State private var attemptCount = 0
    @State private var showingResult = false

    var body: some View {
        ZStack {
            // Camera preview
            CameraPreviewView(capturedImage: $capturedImage)
                .ignoresSafeArea()

            // Overlay
            VStack {
                // Header
                HStack {
                    if !isAlarmTriggered {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                    }

                    Spacer()
                }
                .padding()

                Spacer()

                // Instructions
                VStack(spacing: 8) {
                    Text(isAlarmTriggered ? "Verify to Stop Alarm" : "Verify Your Brush")
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    Text("Take a selfie while brushing your teeth")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding()

                // Capture button
                Button(action: capturePhoto) {
                    ZStack {
                        Circle()
                            .stroke(.white, lineWidth: 4)
                            .frame(width: 80, height: 80)

                        Circle()
                            .fill(.white)
                            .frame(width: 68, height: 68)

                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.black)
                        }
                    }
                }
                .disabled(isProcessing)
                .padding(.bottom, 48)
            }
        }
        .sheet(isPresented: $showingResult) {
            if let result = verificationResult {
                VerificationResultView(
                    result: result,
                    attemptCount: attemptCount,
                    onRetry: {
                        showingResult = false
                        capturedImage = nil
                        verificationResult = nil
                    },
                    onDismiss: {
                        showingResult = false
                        dismiss()
                    },
                    isAlarmTriggered: isAlarmTriggered
                )
                .presentationDetents([.medium])
            }
        }
    }

    private func capturePhoto() {
        guard let image = capturedImage else {
            // Trigger camera capture
            NotificationCenter.default.post(name: .capturePhoto, object: nil)
            return
        }

        isProcessing = true
        attemptCount += 1

        Task {
            let service = VerificationService(modelContext: modelContext)
            let result = await service.verify(image: image)

            await MainActor.run {
                verificationResult = result
                isProcessing = false
                showingResult = true

                if result.passed {
                    handleSuccessfulVerification()
                }
            }
        }
    }

    private func handleSuccessfulVerification() {
        // Update streak
        do {
            let streakService = StreakService(modelContext: modelContext)
            try streakService.recordVerification(wasAlarmDay: isAlarmTriggered)

            // Cancel remaining alarms if this was alarm-triggered
            if isAlarmTriggered {
                Task {
                    let alarmService = AlarmService(modelContext: modelContext)
                    try await alarmService.cancelTodayBackupAlarms()
                }
            }
        } catch {
            print("Failed to record verification: \(error)")
        }
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let capturePhoto = Notification.Name("capturePhoto")
}

// MARK: - Camera Preview

struct CameraPreviewView: UIViewRepresentable {
    @Binding var capturedImage: UIImage?

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.onCapture = { image in
            capturedImage = image
        }
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {}
}

class CameraPreviewUIView: UIView {
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var photoOutput: AVCapturePhotoOutput?

    var onCapture: ((UIImage) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCamera()
        setupNotifications()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCamera()
        setupNotifications()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(capturePhoto),
            name: .capturePhoto,
            object: nil
        )
    }

    private func setupCamera() {
        let session = AVCaptureSession()
        session.sessionPreset = .photo

        // Front camera
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            return
        }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        let output = AVCapturePhotoOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)

        self.captureSession = session
        self.previewLayer = previewLayer
        self.photoOutput = output

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }

    @objc private func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraPreviewUIView: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            return
        }

        DispatchQueue.main.async {
            self.onCapture?(image)
        }
    }
}

#Preview {
    CameraVerificationView(isAlarmTriggered: false)
}
