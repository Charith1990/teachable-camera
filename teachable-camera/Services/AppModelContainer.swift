//
//  AppModelContainer.swift
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

// MARK: - The on-device database
//
// One shared store for the whole app. The live camera screen and the
// teach screen both use this same container, so they always see the same
// taught examples. Nothing here leaves the device.

enum AppModelContainer {

    static let shared: ModelContainer = {
        // List the model types this store holds. Right now just one.
        let schema = Schema([TaughtExample.self])

        // Keep the data on disk so it survives app restarts.
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // If the store cannot be built, the app cannot work at all,
            // so we stop with a clear message instead of failing quietly.
            fatalError("Could not create the Teachable Camera store: \(error)")
        }
    }()
}
