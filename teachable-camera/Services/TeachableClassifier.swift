//
//  TeachableClassifier.swift
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

// A single guess: which label, and how sure we are (0...1).
struct Prediction {
    let label: String
    let confidence: Double
}

// MARK: - Learn and recognise, on-device
//
// This is the "model" that grows on the phone. It holds every taught
// fingerprint in memory. To recognise a new image, it finds the taught
// fingerprint that points in the most similar direction (cosine
// similarity). No training step, no server, no cost.

@MainActor
@Observable
final class TeachableClassifier {

    // Everything taught, kept unpacked in memory so we do not decode bytes
    // on every camera frame.
    private var examples: [(label: String, vector: [Float])] = []

    // How many photos we hold per label. Used by the UI.
    var labelCounts: [String: Int] {
        Dictionary(grouping: examples, by: { $0.label }).mapValues(\.count)
    }

    var isEmpty: Bool { examples.isEmpty }

    // Load everything from the store into memory. Call once at startup and
    // again after teaching.
    func reload(from context: ModelContext) {
        let descriptor = FetchDescriptor<TaughtExample>()
        let saved = (try? context.fetch(descriptor)) ?? []
        examples = saved.map { (label: $0.label, vector: [Float](data: $0.vector)) }
    }

    // Teach one photo: save it to the store and add it to memory.
    func teach(label: String, vector: [Float], context: ModelContext) {
        let example = TaughtExample(label: label, vector: vector.asData)
        context.insert(example)
        try? context.save()
        examples.append((label: label, vector: vector))
    }

    // Recognise: find the taught fingerprint closest to this one.
    // Returns nil if nothing has been taught yet.
    func predict(_ vector: [Float]) -> Prediction? {
        guard !examples.isEmpty else { return nil }

        var bestLabel = ""
        var bestScore = -Double.infinity
        for example in examples {
            let score = Self.cosineSimilarity(vector, example.vector)
            if score > bestScore {
                bestScore = score
                bestLabel = example.label
            }
        }

        // Everyday images are never truly 0% alike, so a raw cosine of ~0.5
        // does not mean "50% sure". We rescale from a floor: anything at or
        // below `floor` counts as unknown (0%), and only a strong match nears
        // 100%. Tune `floor` for your objects (higher = stricter).
        let floor = 0.55
        let confidence = max(0, min(1, (bestScore - floor) / (1 - floor)))
        return Prediction(label: bestLabel, confidence: confidence)
    }

    // Cosine similarity: 1 means the two fingerprints point the same way
    // (very alike), 0 means unrelated.
    private static func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Double {
        guard a.count == b.count else { return -1 }
        var dot = 0.0, normA = 0.0, normB = 0.0
        for i in 0..<a.count {
            let x = Double(a[i]), y = Double(b[i])
            dot += x * y
            normA += x * x
            normB += y * y
        }
        guard normA > 0, normB > 0 else { return -1 }
        return dot / (sqrt(normA) * sqrt(normB))
    }
}
