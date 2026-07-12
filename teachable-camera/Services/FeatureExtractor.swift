//
//  FeatureExtractor.swift
//  teachable-camera
//
//  The 2026 Apple AI Stack · Part 3 — The Traditional Workhorse
//  Core ML · On-Device Personalization
//
//  Created by Charith Gunasekara · https://alexgunasekara.com.au
//  © 2026 Charith Gunasekara · MIT License
//

import Vision
import CoreVideo
import CoreGraphics

// MARK: - Turning an image into numbers
//
// A "feature print" is a list of numbers that describes an image. Vision
// makes it for us using a Core ML model that runs on-device, on the
// Neural Engine. We never send the image anywhere.
//
// Two photos of the same thing give feature prints that are close to each
// other. Two different things give prints that are far apart. That is the
// whole trick behind teaching and recognising.
//
// `nonisolated`: this is stateless work, so it runs off the main actor — on
// the camera's background queue, one frame at a time. That keeps the UI smooth
// while every frame is turned into numbers.

nonisolated enum FeatureExtractor {

    enum ExtractionError: Error {
        case noResult
    }

    // Make a feature print for a live camera frame (a CVPixelBuffer).
    static func vector(from pixelBuffer: CVPixelBuffer,
                       orientation: CGImagePropertyOrientation = .up) throws -> [Float] {
        let request = VNGenerateImageFeaturePrintRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                            orientation: orientation,
                                            options: [:])
        try handler.perform([request])
        return try floats(from: request)
    }

    // Pull the raw numbers out of the request's result.
    private static func floats(from request: VNGenerateImageFeaturePrintRequest) throws -> [Float] {
        guard let observation = request.results?.first else {
            throw ExtractionError.noResult
        }
        let count = observation.elementCount
        var result = [Float](repeating: 0, count: count)
        // The print is stored as bytes; read them back as Floats.
        observation.data.withUnsafeBytes { raw in
            let source = raw.bindMemory(to: Float.self)
            for i in 0..<count { result[i] = source[i] }
        }
        return result
    }
}

// MARK: - Saving the numbers
//
// SwiftData stores bytes, so we pack [Float] to Data and back. This is how
// a feature print becomes a `vector` on a TaughtExample, and how we read it
// out again to compare.

extension Array where Element == Float {

    // Pack the floats into raw bytes for saving.
    var asData: Data {
        withUnsafeBytes { Data($0) }
    }

    // Rebuild the floats from saved bytes.
    init(data: Data) {
        self = data.withUnsafeBytes { raw in
            Array(raw.bindMemory(to: Float.self))
        }
    }
}
