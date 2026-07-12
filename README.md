<div align="center">

# Teachable Camera

**Point the camera at something, give it a name, and the phone learns to spot it live — on-device, with no training and no server.**

![iOS 26+](https://img.shields.io/badge/iOS-26%2B-000000?logo=apple&logoColor=white)
![Swift 6](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)
![Core ML](https://img.shields.io/badge/Core%20ML-Neural%20Engine-8A2BE2)
![Vision](https://img.shields.io/badge/Vision-feature%20prints-1E90FF)
![SwiftData](https://img.shields.io/badge/SwiftData-store-1E90FF)
![License: MIT](https://img.shields.io/badge/License-MIT-3DA639)

Companion project for **[The 2026 Apple AI Stack · Part 3 — The Traditional Workhorse](https://alexgunasekara.com.au/writing/core-ml-traditional-workhorse)** by [Charith Gunasekara](https://alexgunasekara.com.au).

</div>

## Demo

<table align="center">
  <tr>
    <td align="center" width="50%"><img src="docs/toy-detection.gif" width="240" alt="Recognising a taught toy train live"/><br/><sub><b>Recognises a taught toy, live</b></sub></td>
    <td align="center" width="50%"><img src="docs/mug-detection.gif" width="240" alt="Telling two mugs apart on-device"/><br/><sub><b>Tells two mugs apart</b></sub></td>
  </tr>
</table>

*Both taught with a few photos on the phone. It names each one with a confidence bar, and says **Not sure** — with no number — when it does not recognise what it sees. Nothing leaves the device.*

## What it shows

Core ML the old-fashioned way — recognise, don't generate:

- **Vision feature prints** — `VNGenerateImageFeaturePrintRequest` runs a Core ML model on the Neural Engine and turns each camera frame into a vector, on-device.
- **A classifier that grows on the phone** — every taught vector is saved in SwiftData. To recognise a new frame, the app finds the closest saved vector by cosine similarity. No training step, no model to ship, no server, no cost.

```
TEACH                                RECOGNISE  (every frame)
  camera frame                         camera frame
     │                                    │
     ▼                                    ▼
  Vision feature print                 Vision feature print
     │                                    │
     ▼                                    ▼
  label + vector → SwiftData           cosine similarity vs saved vectors
                                          │
                                          ▼
                                       nearest label + confidence → badge
```

## Requirements

- **Xcode 26** (or later)
- **iOS 26+** on a real device. The app needs the camera, so the Simulator will not do.

Note: this uses Apple's 2026 frameworks during the beta. API names may change before release. If something does not compile, check it against the current SDK.

## Getting started

```bash
git clone https://github.com/Charith1990/teachable-camera.git
cd teachable-camera
open teachable-camera.xcodeproj
```
In Xcode: select the **teachable-camera** target, open **Signing & Capabilities**, set **Automatic** signing and pick your **Team**, then run on a real device. If the bundle identifier clashes, change it to something unique like `com.yourname.teachable-camera`.

## Try it

1. Tap **Teach**, type a name (say `Keys`), point at the object, and tap the shutter a few times from different angles.
2. Tap **Done**. Point at the same object — the badge names it, with a confidence bar.
3. Point at something you never taught — it says **Not sure**, with no number. The app will not guess a percentage it cannot back up.

## The files

| File | What it does |
| --- | --- |
| `Services/CameraService.swift` | Runs the live camera, hands each frame out |
| `Services/FeatureExtractor.swift` | Turns a frame into a Vision feature print (Core ML) |
| `Services/TeachableClassifier.swift` | Nearest-neighbor match by cosine similarity |
| `Services/AppModelContainer.swift` | The on-device SwiftData store |
| `Models/TaughtExample.swift` | One saved example: a label + its vector |
| `RecognizerModel.swift` | Ties camera → extractor → classifier → UI |
| `Views/CameraPreview.swift` | Draws the live camera feed |
| `Views/RecognitionBadge.swift` | The result card, or the "Not sure" prompt |
| `ContentView.swift` | The one screen: teach and recognise |
| `teachable_cameraApp.swift` | App entry, injects the store |

## The article

Full write-up: **[The 2026 Apple AI Stack · Part 3](https://alexgunasekara.com.au/writing/core-ml-traditional-workhorse)**, part of a 5-part series on Apple's 2026 AI stack at [alexgunasekara.com.au](https://alexgunasekara.com.au).

## License

[MIT](LICENSE) © 2026 Charith Gunasekara
