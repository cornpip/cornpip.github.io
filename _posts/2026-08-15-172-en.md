---
title: "Introducing the mediapipe_face_mesh Package"
date: 2026-08-15 12:00:00 +0900
categories: [Software, mediapipe_face_mesh]
tags: ["mediapipe_face_mesh", "Flutter package", "face mesh", "Face Detection", "iris", "blendshapes", "head pose", "litert", "Pub.dev"]
math: false
render_with_liquid: false
permalink: /posts/172/
lang: en
alt_lang: ko-KR
alt_url: /posts/172/
---

## Introduction

Earlier this year I wrote a [post](https://cornpip.dev/posts/153/) about building mediapipe_face_mesh. Since then the package has gone from 1.2 to 2.7. Back then it only ran the 468-landmark mesh and relied on an external package for face detection. Now everything from detection to mesh runs in a single package, and it does quite a bit more than what that first post covered.

[mediapipe_face_mesh](https://pub.dev/packages/mediapipe_face_mesh) runs fast, real-time face detection and face mesh inference, including iris landmarks, and builds on the mesh output to provide features like expression recognition, head pose, and real-world distance between landmarks.

The basic architecture is the same as the first post described. The MediaPipe pre/post-processing ops are ported to C/C++ and wired up over FFI. Once a frame lands in the native buffer, everything runs in C++, and that buffer is reused across calls instead of being reallocated. The processing is a faithful port of the official calculator logic. The TFLite (LiteRT) runtime ships as a prebuilt binary bundled with the models, so there are no extra dependencies or setup needed to run them.

What has changed is performance, stability, and coverage. An optimization pass on the inference path brought streaming down to 2ms per frame, and delegates now fall back to CPU no matter which stage fails. On the platform side, Android and iOS support kept improving while Windows x64 joined the lineup, and more platforms are on the way. Let's walk through the changes.

## What's changed since 1.2

**Built-in face detection.** The package used to handle only the mesh and left detection to an external package. Now the detector is built in: detection, mesh, blendshapes, and geometry all run inside one package. The API got simpler too. You used to wire the detection box into the mesh call yourself; now you hand a frame to a single pipeline and it flows from detection to mesh on its own.

It also doesn't detect on every frame. The detector runs only to acquire a face, or to re-acquire one after it's lost; while tracking, the mesh ROI is carried over from the previous frame's landmarks and only the mesh runs. Same design as the official pipeline.

You can still bring your own detector and use just the mesh. ROI tracking is built into the mesh side, so even then you don't need to detect every frame; the only thing you handle yourself is re-acquisition, running your detector again when the face is lost.

**478 landmarks with iris.** The 468-point mesh gained 10 iris points. For a while that meant running a separate iris model after the mesh pass. Now a single attention mesh option gives you all 478 points in one inference, with lips, eyes, and irises refined. If you are building anything gaze-related, the iris coordinates you need are one option away.

**Multi-face tracking.** Multiple faces are detected at once, and each face keeps a stable trackId. The package knows "this face is the same face as last frame", so you never write matching logic yourself. And no matter how many faces are in the frame, the frame is copied only once.

**52 blendshapes.** You get 52 expression coefficients in the same scheme ARKit uses. No more deriving expressions from raw landmark coordinates.

**Geometry and real-world distances.** On top of head pose (yaw, pitch, roll), you can measure the actual distance between any two landmarks in centimeters. Common measurements (IPD, face width, and so on) come as presets.

**Landmark smoothing.** A OneEuro filter is built in. If landmarks jitter on a live stream, turning it on solves most of it.

**Windows support and iOS stability.** Windows (x64) joined the platforms, and iOS now supports the Apple Silicon simulator natively (arm64). A crash when enabling the XNNPACK delegate on iOS is fixed: the bundled headers and binary disagreed about the delegate options struct, and the headers are now synced across all platforms so it cannot happen again. The bundled iOS runtime also shrank from 47MB to 18MB.

## Usage

The code below targets 2.7.1. The API keeps evolving, so treat the latest [README](https://github.com/cornpip/mediapipe_face_mesh) as the source of truth.

Installing is one line.

```
flutter pub add mediapipe_face_mesh
```

It targets Flutter 3.32.0 or newer, Android minSdk 24, and iOS 13.0+.

Create a detector and a mesh processor, then tie them together in a pipeline.

```dart
final faceDetectorProcessor = await FaceDetectorProcessor.create();
final faceMeshProcessor = await FaceMeshProcessor.create(
  enableAttentionMesh: true, // 478 points including iris, recommended
);

final pipeline = FaceMeshInferencePipeline(
  detector: faceDetectorProcessor,
  mesh: faceMeshProcessor,
  landmarkSmoothing: const LandmarkSmoothingOptions(),
);
```

For a single image, feed it straight into the pipeline.

```dart
final result = pipeline.processNv21(nv21Image, rotationDegrees: rotationDegrees);
```

For a live camera, connect the camera plugin's frame stream to the stream processor.

```dart
final inferenceStreamProcessor = FaceMeshInferenceStreamProcessor(pipeline);

inferenceStreamProcessor.processNv21(
  frameController.stream,
  runMeshResolver: (_) => _isMeshActive,
  rotationDegrees: rotationDegrees,
).listen(_handleInferenceResult, onError: onError);
```

Multi-face only changes how the processor is created and which stream call you use.

```dart
final faceMeshProcessor = await FaceMeshProcessor.createForMultiFace(
  enableAttentionMesh: true,
);

inferenceStreamProcessor.processNv21MultiFace(
  frameController.stream,
  maxMeshFaces: 2,
  runMeshResolver: (_) => _isMeshActive,
  rotationDegrees: rotationDegrees,
).listen(_handleMultiInferenceResult, onError: onError);
```

Extract geometry from a mesh result to get head pose and real-world distances.

```dart
final meshResult = result.meshResult!; // null on frames with no face
final geometry = meshResult.estimateGeometry();
final pose = geometry.headPose;
final eyeDistanceCm = geometry.distanceCm(33, 263); // distance between the outer eye corners
```

Blendshapes take a mesh result and return the 52 coefficients. Smile detection is this short.

```dart
final blendshapesProcessor = await FaceBlendshapesProcessor.create();
final blendshapes = blendshapesProcessor.process(meshResult);
final smile = (blendshapes[FaceBlendshape.mouthSmileLeft]! +
    blendshapes[FaceBlendshape.mouthSmileRight]!) / 2;
```

Landmark indices match the official MediaPipe face mesh, so any MediaPipe-based reference (index maps, eye and lip contour indices, and so on) works as-is.
To find the index at a specific spot, try the [landmark viewer](https://cornpip.dev/mediapipe_landmark_viewer/). Spin the mesh around in the 3D view and click a point to see its index.

## Closing

It is still a C++-first implementation with no external dependencies, so adding the package does not weigh your app down. The only Dart dependency is ffi, and the app size increase is about 19.5 MB for an arm64 release build.

The post at the start of the year said "I built it". Now I can say "it is genuinely usable". If you are building anything face-related in Flutter, give it a try.

The contributor experience is still a work in progress and plenty is missing. Like everything else so far, it will get filled in over time. Contributions and discussions are always welcome; open an issue or a PR on [GitHub](https://github.com/cornpip/mediapipe_face_mesh) and I will do my best to respond.
