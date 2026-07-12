//
//  teachable_cameraApp.swift
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

@main
struct teachable_cameraApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(AppModelContainer.shared)
    }
}
