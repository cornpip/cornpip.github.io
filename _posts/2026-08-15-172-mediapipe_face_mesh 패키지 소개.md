---
title: "mediapipe_face_mesh 패키지 소개"
date: 2026-08-15 12:00:00 +0900
categories: [Project, mediapipe_face_mesh]
tags: ["mediapipe_face_mesh", "Flutter package", "face mesh", "Face Detection", "iris", "blendshapes", "head pose", "litert", "Pub.dev"]
math: false
render_with_liquid: false
permalink: /posts/172/
lang: ko-KR
alt_lang: en
alt_url: /en/posts/172/
---

## 들어가며

연초에 [개발기](https://cornpip.dev/posts/153/)를 올렸던 mediapipe_face_mesh 패키지가 그 사이 1.2에서 2.7까지 올라갔다. 처음 글을 쓸 때는 얼굴 감지를 외부에 의존하고 468 랜드마크 mesh만 돌리는 구조였는데, 지금은 감지부터 mesh까지 패키지 하나로 끝나고, 그때 소개한 내용보다 더 많은 기능들이 추가됐다.

[mediapipe_face_mesh](https://pub.dev/packages/mediapipe_face_mesh)는 고성능 실시간으로 얼굴을 인식하고 홍채를 포함한
face_mesh 추론을 할 수 있으며, mesh 결과를 기반으로 표정 인식, 헤드 포즈,
랜드마크 거리 측정 같은 기능을 제공한다.

기본 구조는 연초 글에서 소개한 것과 같다.
MediaPipe의 전후처리 연산을 C/C++로 포팅하고 FFI로 연결했다. 프레임을 네이티브 버퍼로 넘기고 나면 연산은 전부 C++에서 돌고, 그 버퍼도 매번 할당하지 않고 재사용한다. 전후처리는 공식 calculator 로직을 그대로 따라 포팅했다. tflite(LiteRT) 런타임도 직접 빌드한 바이너리를 모델과 함께 번들로 포함해서, 모델을 돌리기 위한 별도 의존성이나 추가 설정이 없다.

구조는 그대로지만 성능, 안정성, 지원 범위는 많이 달라졌다. 추론 경로를 최적화하면서 스트리밍이 프레임당 2ms로 떨어졌고, delegate는 어느 단계에서 실패해도 CPU로 폴백한다. 플랫폼은 기존 Android, iOS 지원을 다듬으면서 Windows(x64)까지 포함되었고 앞으로도 늘려갈 예정이다. 무엇이 달라졌는지 아래에서 더 살펴보자.

## 1.2 이후 달라진 것들

**얼굴 감지 내장.** 예전에는 감지를 다른 패키지에 맡기고 mesh만 담당했는데, 지금은 detector가 패키지에 들어 있다. 감지, mesh, 블렌드셰이프, geometry까지 전부 이 안에서 돈다. API도 간단해졌다. 예전에는 감지 결과의 box를 mesh 호출에 직접 이어줘야 했는데, 지금은 파이프라인 하나에 프레임만 넣으면 감지부터 mesh까지 알아서 흐른다.

또한 매 프레임 감지를 돌리지 않는다. detector는 얼굴을 처음 잡거나 놓쳤을 때만 돌고, 트래킹 중에는 이전 프레임 랜드마크에서 ROI를 이어받아 mesh만 돈다. 공식 파이프라인과 같은 설계다.

외부 detector를 계속 쓰고 싶으면 mesh만 붙이는 것도 여전히 가능하다. 이 경우에도 ROI 트래킹은 mesh 쪽에 내장돼 있어 매 프레임 감지가 필요한 건 아니고, 얼굴을 놓쳤을 때 다시 감지해서 넘겨주는 재획득 처리만 직접 하면 된다.

**478 랜드마크와 홍채.** 468 mesh에 홍채 10포인트가 추가됐다. 중간에는 mesh 추론 뒤에 별도 iris 모델을 한 번 더 돌려서 홍채를 얹는 방식이었는데, 지금은 attention mesh 옵션 하나면 한 번의 추론으로 입/눈/홍채까지 정밀화된 478 포인트가 바로 나온다. 시선 관련 기능에 필수인 홍채 좌표가 옵션 하나로 끝난다.

**멀티 페이스 트래킹.** 여러 얼굴을 동시에 감지하고, 얼굴마다 trackId가 유지된다. 프레임 사이에서 "이 얼굴이 아까 그 얼굴"이라는 걸 패키지가 알고 있으니, 사용하는 쪽에서 매칭 로직을 짤 필요가 없다. 여러 얼굴을 처리해도 프레임 복사는 한 번이다.

**블렌드셰이프 52개.** ARKit과 같은 규격의 표정 계수 52개를 받는다. 랜드마크 좌표에서 표정을 직접 계산할 필요가 없어졌다.

**geometry와 실측 거리.** 헤드 포즈(yaw, pitch, roll)에 더해, 랜드마크 두 점 사이의 실제 거리를 cm 단위로 잴 수 있다. 자주 쓰는 조합(IPD, 얼굴 폭 등)은 프리셋으로도 제공한다.

**랜드마크 스무딩.** OneEuro 필터가 들어갔다. 실시간 스트림에서 포인트가 떨리는 문제는 이걸 켜면 대부분 해결된다.

**Windows 지원과 iOS 안정화.** 플랫폼에 Windows(x64)가 추가됐고, iOS는 Apple Silicon 시뮬레이터를 네이티브(arm64)로 지원한다. iOS에서 XNNPACK delegate를 켜면 크래시가 나던 문제도 잡았다. 번들된 헤더와 바이너리가 delegate 옵션 struct를 서로 다르게 보던 게 원인이었는데, 헤더를 전 플랫폼과 동기화해서 재발까지 막았다. 번들 런타임도 47MB에서 18MB로 줄었다.

## 사용법

아래 코드는 2.7.1 기준이다. 실제 사용 시 최신 버전의 [README](https://github.com/cornpip/mediapipe_face_mesh)를 기준으로 참고하길 바란다.

설치는 한 줄이다.

```
flutter pub add mediapipe_face_mesh
```

Flutter 3.32.0 이상, Android는 minSdk 24, iOS는 13.0 이상을 타겟한다.

detector와 mesh processor를 만들고 파이프라인으로 묶는 구조다.

```dart
final faceDetectorProcessor = await FaceDetectorProcessor.create();
final faceMeshProcessor = await FaceMeshProcessor.create(
  enableAttentionMesh: true, // 홍채 포함 478 포인트, 권장
);

final pipeline = FaceMeshInferencePipeline(
  detector: faceDetectorProcessor,
  mesh: faceMeshProcessor,
  landmarkSmoothing: const LandmarkSmoothingOptions(),
);
```

단일 이미지는 파이프라인에 바로 넣으면 된다.

```dart
final result = pipeline.processNv21(nv21Image, rotationDegrees: rotationDegrees);
```

카메라 스트림은 스트림 프로세서에 camera 플러그인의 프레임 스트림을 연결한다.

```dart
final inferenceStreamProcessor = FaceMeshInferenceStreamProcessor(pipeline);

inferenceStreamProcessor.processNv21(
  frameController.stream,
  runMeshResolver: (_) => _isMeshActive,
  rotationDegrees: rotationDegrees,
).listen(_handleInferenceResult, onError: onError);
```

멀티 페이스는 processor 생성과 스트림 호출이 바뀐다.

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

mesh 결과에서 geometry를 뽑으면 헤드 포즈와 실측 거리가 나온다.

```dart
final meshResult = result.meshResult!; // 얼굴이 없는 프레임에서는 null
final geometry = meshResult.estimateGeometry();
final pose = geometry.headPose;
final eyeDistanceCm = geometry.distanceCm(33, 263); // 양쪽 눈꼬리 거리
```

블렌드셰이프는 mesh 결과를 넣으면 계수 52개가 나온다. 웃음 감지는 이 정도로 끝난다.

```dart
final blendshapesProcessor = await FaceBlendshapesProcessor.create();
final blendshapes = blendshapesProcessor.process(meshResult);
final smile = (blendshapes[FaceBlendshape.mouthSmileLeft]! +
    blendshapes[FaceBlendshape.mouthSmileRight]!) / 2;
```

랜드마크 인덱스는 MediaPipe 공식 face mesh와 동일해서, MediaPipe 기준으로 정리된 자료(인덱스 맵, 눈/입 윤곽 인덱스 등)를 그대로 쓸 수 있다.
원하는 위치의 인덱스를 찾을 때는 [landmark viewer](https://cornpip.dev/mediapipe_landmark_viewer/)도 사용해 보길 바란다. 3D 뷰에서 mesh를 돌려보며, 포인트를 클릭하면 인덱스가 바로 나와 편하게 볼 수 있다.

## 마무리

여전히 외부 의존성 없이 C++ 위주 구현이라, 패키지를 추가해도 앱이 무거워지지 않는다. Dart 쪽 의존성은 ffi 하나고, arm64 release 기준 앱 사이즈 증가분은 약 19.5 MB다.

연초 글에서 "만들었다"고 소개했다면, 지금은 "충분히 쓸만하다"고 말할 수 있는 상태다. Flutter에서 얼굴 관련 기능을 만든다면 도입해보길 바란다.

기여 환경은 아직 갖춰가는 중이라 미흡한 부분이 많다. 하지만 지금까지 그래왔듯 차차 채워갈 예정이다. 기여와 논의는 언제나 환영하고, [GitHub](https://github.com/cornpip/mediapipe_face_mesh)에 이슈나 PR을 열어주면 성심껏 답하겠다.
