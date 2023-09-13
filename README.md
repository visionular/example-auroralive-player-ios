# example-auroralive-player-ios

## Install SDK

#### Swift Package

```swift
let package = Package(
  ...
  dependencies: [
    .package(name: "AuroraLivePlayerSDK", url: "https://github.com/visionular/auroralive-player-spec.git", .upToNextMajor("1.0.0")),
  ],
  targets: [
    .target(
      name: "MyApp",
      dependencies: ["AuroraLivePlayerSDK"]
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
