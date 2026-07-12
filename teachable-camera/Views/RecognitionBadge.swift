//
//  RecognitionBadge.swift
//  teachable-camera
//
//  The 2026 Apple AI Stack · Part 3 — The Traditional Workhorse
//  Core ML · On-Device Personalization
//
//  Created by Charith Gunasekara · https://alexgunasekara.com.au
//  © 2026 Charith Gunasekara · MIT License
//

import SwiftUI

// MARK: - Animated recognition badge
//
// Two states, so we never show a misleading number:
//   • Confident  → full card: name (slides in), confidence bar (glides),
//                  percentage (rolls), seal icon (bounces on lock-on).
//   • Not sure   → a plain prompt with NO percentage.
// The two states cross-fade with a spring when confidence crosses the line.

struct RecognitionBadge: View {

    let prediction: Prediction
    let minConfidence: Double

    private var isConfident: Bool { prediction.confidence >= minConfidence }
    private var percent: Int { Int((prediction.confidence * 100).rounded()) }

    var body: some View {
        ZStack {
            if isConfident {
                confidentCard
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
            } else {
                notSurePrompt
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.78), value: isConfident)
    }

    // MARK: Confident

    private var confidentCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                    .symbolEffect(.bounce, value: prediction.label)

                Text(prediction.label)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .id(prediction.label)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)))
            }

            HStack(spacing: 12) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.25))
                        Capsule().fill(.green)
                            .frame(width: max(6, geo.size.width * prediction.confidence))
                    }
                }
                .frame(height: 8)

                Text("\(percent)%")
                    .font(.title3.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(maxWidth: 320)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.green.opacity(0.8), lineWidth: 1.5)
        )
        .shadow(color: .green.opacity(0.45), radius: 12)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: prediction.label)
        .animation(.easeOut(duration: 0.3), value: prediction.confidence)
    }

    // MARK: Not sure — no number shown

    private var notSurePrompt: some View {
        Label("Not sure — point at something you taught", systemImage: "viewfinder")
            .font(.headline)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: Capsule())
            .foregroundStyle(.white)
    }
}
