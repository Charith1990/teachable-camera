//
//  TaughtExample.swift
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

// MARK: - Stored teaching example
//
// One row here = one photo the user taught the app.
//
// We keep two things: the label (the name the user typed) and the
// "feature print" for that photo. A feature print is a list of numbers
// that describes what the image looks like. Vision makes it for us,
// on-device, using a Core ML model. We build it in FeatureExtractor.swift.
//
// We store the numbers as `Data` (raw bytes), not as [Float]. Bytes are
// small on disk and simple for SwiftData to save. We turn the bytes back
// into [Float] only when we need to compare two images.

@Model
final class TaughtExample {

    // The category name the user gave, e.g. "My keys" or "Coffee mug".
    var label: String

    // The feature print for one photo, packed into bytes.
    var vector: Data

    // When the user taught it. Handy for sorting the list and for cleanup.
    var createdAt: Date

    init(label: String, vector: Data, createdAt: Date = .now) {
        self.label = label
        self.vector = vector
        self.createdAt = createdAt
    }
}
