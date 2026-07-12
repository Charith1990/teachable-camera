//
//  RecognizerModel.swift
//  teachable-camera
//
//  The 2026 Apple AI Stack · Part 3 — The Traditional Workhorse
//  Core ML · On-Device Personalization
//
//  Created by Charith Gunasekara · https://alexgunasekara.com.au
//  © 2026 Charith Gunasekara · MIT License
//

import Foundation
import SwiftData
import ImageIO   // for CGImagePropertyOrientation (used when reading a frame)

// MARK: - The brain that connects camera → classifier → UI
//
// It owns the camera and the classifier, listens to live frames, turns each
// one into a fingerprint, asks the classifier what it is, and publishes the
// answer. The views only read from here.
//
// @MainActor keeps all of this state on one thread, so there are no data
// races when the background camera frame hops over to update the UI.

@MainActor
@Observable
final class RecognizerModel {

    let camera = CameraService()
    let classifier = TeachableClassifier()

    // The current live guess, shown on screen.
    var prediction: Prediction?

    // Camera permission state, so the UI can prompt if needed.
    var cameraDenied = false

    // The most recent frame's fingerprint. The teach flow uses this.
    private(set) var latestVector: [Float]?

    private var context: ModelContext?

    // How many photos we hold per label, for the UI.
    var labelCounts: [String: Int] { classifier.labelCounts }

    // Start everything: load what we know, wire the frame handler, run the camera.
    func start(context: ModelContext) async {
        self.context = context
        classifier.reload(from: context)

        camera.onFrame = { [weak self] pixelBuffer in
            // This runs on the camera's background queue. Making the
            // fingerprint here is fast and keeps the UI smooth.
            guard let vector = try? FeatureExtractor.vector(from: pixelBuffer,
                                                            orientation: .right)
            else { return }
            Task { @MainActor in
                self?.handle(vector)
            }
        }

        let started = await camera.start()
        cameraDenied = !started
    }

    // Smoothed confidence, so the on-screen bar and percentage glide instead
    // of jumping on every frame.
    private var smoothedConfidence = 0.0

    private func handle(_ vector: [Float]) {
        latestVector = vector

        guard let raw = classifier.predict(vector) else {
            prediction = nil
            return
        }

        // Same object: ease toward the new value. New object: snap to it.
        if prediction?.label == raw.label {
            smoothedConfidence = smoothedConfidence * 0.7 + raw.confidence * 0.3
        } else {
            smoothedConfidence = raw.confidence
        }

        prediction = Prediction(label: raw.label, confidence: smoothedConfidence)
    }

    // Teach the current view one example of `label`, using the latest frame.
    func teachCurrent(label: String) {
        guard let vector = latestVector, let context else { return }
        classifier.teach(label: label, vector: vector, context: context)
    }
}
