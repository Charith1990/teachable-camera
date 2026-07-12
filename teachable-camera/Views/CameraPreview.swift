//
//  CameraPreview.swift
//  teachable-camera
//
//  The 2026 Apple AI Stack · Part 3 — The Traditional Workhorse
//  Core ML · On-Device Personalization
//
//  Created by Charith Gunasekara · https://alexgunasekara.com.au
//  © 2026 Charith Gunasekara · MIT License
//

import SwiftUI
import AVFoundation

// MARK: - Live camera preview
//
// SwiftUI has no native camera view, so we wrap the UIKit layer that draws
// the camera feed (AVCaptureVideoPreviewLayer) and hand it the session.

struct CameraPreview: UIViewRepresentable {

    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        // Nothing to update — the session does not change after setup.
    }

    // A UIView whose backing layer IS the preview layer. Because the layer
    // is the view's own layer, it resizes with the view automatically, so
    // there is no manual frame maths to keep in sync.
    final class PreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}
