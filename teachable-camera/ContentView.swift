//
//  ContentView.swift
//  teachable-camera
//
//  The 2026 Apple AI Stack · Part 3 — The Traditional Workhorse
//  Core ML · On-Device Personalization
//
//  Created by Charith Gunasekara · https://alexgunasekara.com.au
//  © 2026 Charith Gunasekara · MIT License
//

import SwiftUI
import SwiftData

// MARK: - Main screen
//
// One live camera view that never goes away. It has two modes on top of it:
//   • Recognise — shows the current guess.
//   • Teach     — an overlay to name an object and add samples.
// Keeping a single camera preview (instead of a separate sheet) means the
// screen never goes blank when you finish teaching.

struct ContentView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var model = RecognizerModel()

    // Teach-mode state.
    @State private var isTeaching = false
    @State private var teachLabel = ""
    @State private var samplesAdded = 0
    @State private var flash = false
    @FocusState private var nameFocused: Bool

    // Show a name only above this calibrated confidence; below it we say
    // "Not sure" with no number. Tunable — pair it with `floor` in
    // TeachableClassifier. Lower = more eager to name things.
    private let minConfidence = 0.60

    var body: some View {
        ZStack {
            // The live camera, always on screen — never torn down.
            CameraPreview(session: model.camera.session)
                .ignoresSafeArea()

            // A quick flash when a sample is captured.
            Color.white
                .opacity(flash ? 0.35 : 0)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            if model.cameraDenied {
                deniedView
            } else {
                reticle

                VStack {
                    topBar
                    Spacer()
                    bottomBar
                }
                .padding()
            }
        }
        .task { await model.start(context: modelContext) }
        .sensoryFeedback(.impact, trigger: samplesAdded)
        .animation(.easeInOut(duration: 0.25), value: isTeaching)
    }

    // MARK: Top bar

    @ViewBuilder
    private var topBar: some View {
        if isTeaching {
            HStack {
                pill(teachLabel.isEmpty ? "Name your object" : "Teaching “\(teachLabel)”",
                     icon: "graduationcap.fill")
                Spacer()
                Button { stopTeaching() } label: {
                    Text("Done").font(.headline.bold())
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                        .foregroundStyle(.white)
                }
            }
        } else {
            predictionBadge
                .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var predictionBadge: some View {
        if model.classifier.isEmpty {
            pill("Teach me something to get started", icon: "sparkles")
        } else if let guess = model.prediction {
            RecognitionBadge(prediction: guess, minConfidence: minConfidence)
        } else {
            pill("Looking…", icon: "viewfinder")
        }
    }

    // MARK: Center reticle

    private var reticleLocked: Bool {
        !isTeaching && (model.prediction?.confidence ?? 0) >= minConfidence
    }

    private var reticleColor: Color {
        if isTeaching { return .yellow }
        return reticleLocked ? .green : .white.opacity(0.85)
    }

    private var reticle: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .stroke(reticleColor, lineWidth: 3)
            .frame(width: 250, height: 250)
            .scaleEffect(reticleLocked ? 0.92 : 1.0)
            .shadow(color: reticleColor.opacity(reticleLocked ? 0.6 : 0.3),
                    radius: reticleLocked ? 10 : 6)
            .allowsHitTesting(false)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: reticleLocked)
            .animation(.easeInOut(duration: 0.3), value: reticleColor)
    }

    // MARK: Bottom bar

    @ViewBuilder
    private var bottomBar: some View {
        if isTeaching {
            teachControls
        } else {
            recogniseControls
        }
    }

    private var recogniseControls: some View {
        HStack {
            let photos = model.labelCounts.values.reduce(0, +)
            pill("\(model.labelCounts.count) labels · \(photos) photos",
                 icon: "brain.head.profile", font: .subheadline)

            Spacer()

            Button { startTeaching() } label: {
                Label("Teach", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding(.horizontal, 18).padding(.vertical, 12)
                    .background(.tint, in: Capsule())
                    .foregroundStyle(.white)
            }
        }
    }

    private var teachControls: some View {
        VStack(spacing: 12) {
            if samplesAdded > 0 {
                pill("\(samplesAdded) sample\(samplesAdded == 1 ? "" : "s") added — move around and add more",
                     icon: "checkmark.circle.fill", font: .footnote)
            }

            HStack(spacing: 12) {
                TextField("Object name", text: $teachLabel)
                    .focused($nameFocused)
                    .submitLabel(.done)
                    .onSubmit { nameFocused = false }
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 16).padding(.vertical, 14)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.white)

                Button { addSample() } label: {
                    Image(systemName: "camera.aperture")
                        .font(.title2.bold())
                        .frame(width: 56, height: 56)
                        .background(canCapture ? AnyShapeStyle(.tint) : AnyShapeStyle(.gray.opacity(0.6)),
                                    in: Circle())
                        .foregroundStyle(.white)
                }
                .disabled(!canCapture)
            }
        }
    }

    private var canCapture: Bool {
        !teachLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && model.latestVector != nil
    }

    // MARK: Reusable pill

    private func pill(_ text: String, icon: String, font: Font = .headline) -> some View {
        Label(text, systemImage: icon)
            .font(font)
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .foregroundStyle(.white)
    }

    // MARK: Actions

    private func startTeaching() {
        teachLabel = ""
        samplesAdded = 0
        isTeaching = true
        nameFocused = true
    }

    private func stopTeaching() {
        nameFocused = false
        isTeaching = false
    }

    private func addSample() {
        let name = teachLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        nameFocused = false               // free the view so taps are unobstructed
        model.teachCurrent(label: name)
        samplesAdded += 1

        // Quick capture flash.
        withAnimation(.easeOut(duration: 0.10)) { flash = true }
        withAnimation(.easeIn(duration: 0.25).delay(0.10)) { flash = false }
    }

    private var deniedView: some View {
        ContentUnavailableView {
            Label("Camera access needed", systemImage: "camera.fill")
        } description: {
            Text("Teachable Camera needs the camera to recognise objects. Turn it on in Settings › Teachable Camera.")
        }
    }
}
