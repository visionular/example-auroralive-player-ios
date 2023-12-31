# example-auroralive-player-ios

## Docs

Source Docs: https://docs.visionular.com/auroralive/playersdk/ios/

## Install SDK

#### Swift Package

```swift
let package = Package(
  ...
  dependencies: [
    //  Apple spm binaryTarget doesn't support dependencies params, need to add a WebRTC dependency here.
    .package(name: "WebRTC", url: "https://github.com/webrtc-sdk/Specs.git", .exact("114.5735.05"),
    .package(name: "AuroraLivePlayerSDK", url: "https://github.com/visionular/auroralive-player-spec.git", .upToNextMajor("1.0.4")),
  ],
  targets: [
    .target(
      name: "MyApp",
      dependencies: ["WebRTC", "AuroraLivePlayerSDK"]
    )
  ]
)
```

#### Pods

Add this dependency to your Podfile:

```podspec
pod 'AuroraLivePlayerSDK'
```

## Create the Player

```swift
import AuroraLivePlayerSDK

// <self> implements AuroraLivePlayerDelegate
let player = AuroraLivePlayer()
player.add(delegate: self)

```

## Play a Stream

The SDK provide VideoView, a UIView subclass. And also provides SwiftUI View, you can refer to the example source code.

```swift

// add view to your content view
let videoView = VideoView()
view.addSubview(videoView)

// The player loads the stream asynchronously.
player.play(playbackId: <your_playback_id>, token: <your_jwt_token>)

// delegate. display video 
func player(_ player: AuroraLivePlayer, didTrack videoTrack: VideoTrack) {
    DispatchQueue.main.async {
        videoView.track = track
    }
}

// delegate. load stream error
func player(_ player: AuroraLivePlayer, didPlayError error: Error) {
    // ....
}

// delegate. load stream success
func playerDidPlaySuccess(_ player: AuroraLivePlayer) {
    print("play success")
}

```

## Release the Player

```swift
player.close()
```
