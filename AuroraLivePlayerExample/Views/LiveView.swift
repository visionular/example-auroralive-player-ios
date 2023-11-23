//
//  LiveView.swift
//  AuroraLivePlayerExample
//
//  Created by retamia on 2023/9/12.
//

import SwiftUI
import AuroraLivePlayerSDK
import SimpleToast

extension Binding {
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        return Binding(
            get: { self.wrappedValue },
            set: { selection in
                self.wrappedValue = selection
                handler(selection)
        })
    }
}

internal class VideoViewDelegateReceiver: VideoViewDelegate, ObservableObject {

    @Published var isRendering: Bool = false
    @Published var firstFrameTimestamp: Int = 0

    init() {
    }

    public func videoView(_ videoView: VideoView, didUpdate isRendering: Bool) {
        Task.detached { @MainActor in
            self.isRendering = isRendering
            if(isRendering == true && self.firstFrameTimestamp == 0){
                self.firstFrameTimestamp = Int(1000 * Date().timeIntervalSince1970)
            }
        }
    }
}

internal class PlayerDelegateReceiver: AuroraLivePlayerDelegate, ObservableObject {
    @Published var loadError: Error? = nil
    @Published var layerError: Error? = nil
    var lastBytes = 0
    @Published var videoPktLost = 0
    @Published var audioPktLost = 0
    @Published var bitrate = 0
    @Published var width = 0
    @Published var height = 0
    @Published var fps = 0.0
    @Published var lastPacketReceivedTimestamp: Int64 = 0
    @Published var jitterBufferMs: Int = 0
    @Published var keyFrameCount: Int = 0
    @Published var pliCount: Int = 0
    @Published var nackCount: Int = 0
    @Published var freezeCount: Int = 0
    @Published var freezeDuration: Double = 0.0
    @Published var rtt : Double = 0.0
    @Published var packets : Int = 0
    @Published var layers: [AuroraLiveLayer] = []
    @Published var currentLayer = 0
    @Published var showToast: Bool = false
    @Published var errorEvent: Bool = false
    @Published var toastMsg: String = ""
    @Published var signalTimestamp: Int = 0
    
    init() {
    }
    
    func player(_ player: AuroraLivePlayer, didPlayError error: Error) {
        Task.detached { @MainActor in
            self.showToast = true
            self.errorEvent = true
            self.toastMsg = "play error \(error.localizedDescription)"
            self.loadError = error
        }
    }
    
    func player(_ player: AuroraLivePlayer, didPlaySuccess streamInfo: StreamInfo) {
        Task.detached { @MainActor in
            self.showToast = true
            self.errorEvent = false
            self.toastMsg = "play success"
	    self.signalTimestamp = Int(1000 * Date().timeIntervalSince1970)
            self.layers.removeAll()
            self.currentLayer = streamInfo.videoLayersInfo!.current
            streamInfo.videoLayersInfo!.layers.forEach { element in
                self.layers.append(AuroraLiveLayer(desc: String(element.width)+"x"+String(element.height), value: element.rid))
            }
        }
    }
    
    func player(_ player: AuroraLivePlayer, didStats stats: AuroraLiveStats) {
        let kbps = (stats.videoBytesReceived - lastBytes) * 8 / 1000
        lastBytes = stats.videoBytesReceived
        Task.detached { @MainActor in
            self.videoPktLost = stats.videoPacketsLost
            self.audioPktLost = stats.audioPacketsLost
            self.bitrate = kbps
            self.width = stats.videoWidth
            self.height = stats.videoHeight
            self.fps = stats.videoFps
            self.lastPacketReceivedTimestamp = stats.lastPacketReceivedTimestamp
            self.jitterBufferMs = stats.jitterBufferMs
            self.keyFrameCount = stats.keyFrameCount
            self.nackCount = stats.nackCount
            self.pliCount = stats.pliCount
            self.freezeCount = stats.freezeCount
            self.freezeDuration = stats.freezeDuration
            self.rtt = stats.rtt
            self.packets = stats.videoPacketsReceived + stats.audioPacketsReceived
        }
    }
    
    func player(_ player: AuroraLivePlayer, didSelectLayerError error: Error) {
        Task.detached { @MainActor in
            self.showToast = true
            self.errorEvent = true
            self.toastMsg = "switch layer error \(error.localizedDescription)"
            self.layerError = error
        }

    }

    func playerDidSelectLayerSuccess(_ player: AuroraLivePlayer) {
        Task.detached { @MainActor in
            self.showToast = true
            self.errorEvent = false
            self.toastMsg = "switch layer success"
        }

    }
}

struct LiveView: View {
    
    @ObservedObject var player: AuroraLivePlayer
    @ObservedObject var playerDelegateReceiver: PlayerDelegateReceiver
    @ObservedObject var videoViewDelegateReceiver: VideoViewDelegateReceiver
    
    @State private var isRendering: Bool = false
    @State private var loaded: Bool = false
    @State private var startPlayTime: Int = 0
    private let toastOptions = SimpleToastOptions(hideAfter: 3)
    
    let dateFormatter = DateFormatter()
    let playbackId: String
    let token: String
    
    let statTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(playbackId: String, token: String) {
        self.player = AuroraLivePlayer()
        self.playerDelegateReceiver = PlayerDelegateReceiver()
        self.videoViewDelegateReceiver = VideoViewDelegateReceiver()
        self.playbackId = playbackId
        self.token = token
        self.player.add(delegate: playerDelegateReceiver)
        self.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    }
    
    func layerChange(_ layer: Int) {
        player.layer(layer: playerDelegateReceiver.layers[layer])
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Background color
                Color.black.ignoresSafeArea()
            }
            
            ZStack(alignment: .topLeading) {
                VStack(alignment: .leading) {
                    HStack(alignment: .center) {
                        Text("choose layer:").foregroundColor(.white)
                        Picker(selection: $playerDelegateReceiver.currentLayer.onChange(layerChange), label: Text("choose a layer")) {
                            ForEach(playerDelegateReceiver.layers.indices, id: \.self) { i in
                                Text(playerDelegateReceiver.layers[i].desc)
                            }
                        }
                    }
                    Group {
                        Text(verbatim: "Clinet Time: \(dateFormatter.string(from: Date()))").foregroundColor(.white)
                        Text(verbatim: "Resolution: \(playerDelegateReceiver.width)x\(playerDelegateReceiver.height)").foregroundColor(.white)
                        Text(verbatim: "Signal Cost: \(playerDelegateReceiver.signalTimestamp > 0 ? (playerDelegateReceiver.signalTimestamp - startPlayTime):0) ms").foregroundColor(.white)
                        Text(verbatim: "First Frame Render: \(videoViewDelegateReceiver.firstFrameTimestamp > 0 ? (videoViewDelegateReceiver.firstFrameTimestamp - startPlayTime):0) ms").foregroundColor(.white)
                        Text(verbatim: "Fps: \(playerDelegateReceiver.fps)").foregroundColor(.white)
                        Text(verbatim: "Bitrate: \(playerDelegateReceiver.bitrate) kbits/sec").foregroundColor(.white)
                        Text(verbatim: "PTS: \(playerDelegateReceiver.lastPacketReceivedTimestamp)").foregroundColor(.white)
                    }
                    Group {
                        Text(verbatim: "JB Ms: \(playerDelegateReceiver.jitterBufferMs) ms").foregroundColor(.white)
                        Text(verbatim: "Keyframe: \(playerDelegateReceiver.keyFrameCount)").foregroundColor(.white)
                        Text(verbatim: "PLI: \(playerDelegateReceiver.pliCount)").foregroundColor(.white)
                        Text(verbatim: "NACK: \(playerDelegateReceiver.nackCount)").foregroundColor(.white)
                        Text(verbatim: "Freeze: \(playerDelegateReceiver.freezeCount) \(playerDelegateReceiver.freezeDuration) s").foregroundColor(.white)
                        Text(verbatim: "Packets: \(playerDelegateReceiver.packets)").foregroundColor(.white)
                        Text(verbatim: "Packet Loss: A=\(playerDelegateReceiver.audioPktLost) V=\(playerDelegateReceiver.videoPktLost)").foregroundColor(.white)
                        Text(verbatim: "RTT: \(playerDelegateReceiver.rtt) ms").foregroundColor(.white)
                    }
                    ZStack(alignment: .bottom) {
                        if playerDelegateReceiver.loadError == nil {
                            SwiftUIVideoView($player.videoTrack, isRendering: $isRendering, layoutMode: .fit, debug: false, videoViewDelegate: videoViewDelegateReceiver)
                                .onAppear {
                                    if playbackId.isEmpty {
                                        return
                                    }
                                    
                                    if !loaded {
                                        loaded = true
                                        startPlayTime = Int(1000 * Date().timeIntervalSince1970)
                                        player.play(playbackId: playbackId, token: token.isEmpty ? nil : token)
                                    }
                                }
                                .onDisappear {
                                    if loaded {
                                        player.close()
                                        loaded = false
                                    }
                                    
                                    playerDelegateReceiver.loadError = nil
                                    videoViewDelegateReceiver.firstFrameTimestamp = 0
                                }
                            
                            if !isRendering {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            }
                        }  else {
                            Text(verbatim: "error: \(playerDelegateReceiver.loadError!.localizedDescription)").foregroundColor(.white)
                        }
                    }
                    .simpleToast(isPresented: $playerDelegateReceiver.showToast, options: toastOptions) {
                        Label(playerDelegateReceiver.toastMsg, systemImage: "")
                            .padding()
                            .background(playerDelegateReceiver.errorEvent ? Color.red.opacity(0.8) :  Color.green.opacity(0.8))
                            .foregroundColor(Color.white)
                            .cornerRadius(10)
                            .padding(.top)
                        }
                }
            }
        }
        .navigationBarTitle(playbackId)
        .onReceive(statTimer) { _ in
            player.getStats()
        }
    }
    
}

struct LiveView_Previews: PreviewProvider {
    static var previews: some View {
        LiveView(playbackId: "", token: "")
    }
}
