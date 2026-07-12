//
//  CameraService.swift
//  teachable-camera
//
//  The 2026 Apple AI Stack · Part 3 — The Traditional Workhorse
//  Core ML · On-Device Personalization
//
//  Created by Charith Gunasekara · https://alexgunasekara.com.au
//  © 2026 Charith Gunasekara · MIT License
//

@preconcurrency import AVFoundation
import CoreVideo

// MARK: - The live camera
//
// One job: run the capture session and hand each live frame to `onFrame`.
// Both jobs in the app use these frames — recognising (every frame) and
// teaching (grab the current frame). We never need a separate photo.
//
// AVFoundation calls its delegate on a background queue, so all session
// work stays on `sessionQueue`, and the class is marked @unchecked Sendable
// (we promise to keep that work confined to the queue).
//
// `nonisolated`: this whole service lives off the main actor. The app defaults
// new types to @MainActor, but the camera runs on `sessionQueue`, so we opt
// the class out. That is what lets the queue closures touch `session` freely.

nonisolated final class CameraService: NSObject, @unchecked Sendable {

    // The session the SwiftUI preview layer shows.
    let session = AVCaptureSession()

    // Called on a background queue for every live frame.
    // Set this once, before calling start().
    var onFrame: (@Sendable (CVPixelBuffer) -> Void)?

    private let sessionQueue = DispatchQueue(label: "TeachableCamera.session")
    private let videoOutput = AVCaptureVideoDataOutput()
    private var isConfigured = false

    // Ask permission, build the session once, and start it.
    // Returns false if the user denied camera access.
    @discardableResult
    func start() async -> Bool {
        guard await requestAccess() else { return false }
        await withCheckedContinuation { continuation in
            sessionQueue.async { [self] in
                configureIfNeeded()
                if !session.isRunning { session.startRunning() }
                continuation.resume()
            }
        }
        return true
    }

    func stop() {
        sessionQueue.async { [self] in
            if session.isRunning { session.stopRunning() }
        }
    }

    private func requestAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }

    // Build the session once: a back-camera input and a live-frame output.
    private func configureIfNeeded() {
        guard !isConfigured else { return }
        isConfigured = true

        session.beginConfiguration()
        session.sessionPreset = .high

        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
           let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
        }

        // Drop frames we fall behind on, so recognition always uses a fresh one.
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }

        session.commitConfiguration()
    }
}

// MARK: - Live frame delivery
//
// AVFoundation calls `captureOutput` on the background queue, so this whole
// conformance is `nonisolated` — it must not hop to the main actor per frame.
nonisolated extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        onFrame?(pixelBuffer)
    }
}
