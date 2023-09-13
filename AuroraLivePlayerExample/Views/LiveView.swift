//
//  LiveView.swift
//  AuroraLivePlayerExample
//
//  Created by retamia on 2023/9/12.
//

import SwiftUI
import AuroraLivePlayerSDK

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

extension AuroraLiveLayer {
    var displayText: String {
        switch self {
        case .high: return "High"
        case .low: return "Low"
        case .medium: return "Medium"
        case .unknown: return "Unknown"
        @unknown default:
            return "Unknown"
        }
    }
}

internal class PlayerDelegateReceiver: AuroraLivePlayerDelegate, ObservableObject {
    @Published var loadError: Error? = nil
    @Published var layerError: Error? = nil
    var lastBytes = 0
    @Published var pktLost = 0
    @Published var bitrate = 0
    
    init() {
    }
    
    func player(_ player: AuroraLivePlayer, didPlayError error: Error) {
        Task.detached { @MainActor in
            self.loadError = error
        }
    }
    
    func playerDidPlaySuccess(_ player: AuroraLivePlayer) {
        print("play success")
    }
    
    func player(_ player: AuroraLivePlayer, didStats stats: AuroraLiveStats) {
        let kbps = (stats.videoBytesReceived - lastBytes) * 8 / 1000
        lastBytes = stats.videoBytesReceived
        Task.detached { @MainActor in
            self.pktLost = stats.videoPacketsLost
            self.bitrate = kbps
        }
    }
    
    func player(_ player: AuroraLivePlayer, didSelectLayerError error: Error) {
        Task.detached { @MainActor in
            self.layerError = error
        }

    }
}

struct LiveView: View {
    
    @ObservedObject var player: AuroraLivePlayer
    @ObservedObject var playerDelegateReceiver: PlayerDelegateReceiver
    
    @State private var isRendering: Bool = false
    @State private var loaded: Bool = false
    @State private var selectedLayer: AuroraLiveLayer = .low
    
    let playbackId: String
    let token: String
    let layers: [AuroraLiveLayer]

    
    let statTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    

    
    init(playbackId: String, token: String) {
        self.player = AuroraLivePlayer()
        self.playerDelegateReceiver = PlayerDelegateReceiver()
        self.playbackId = playbackId
        self.token = token
        self.layers = [.low, .medium, .high]
        self.player.add(delegate: playerDelegateReceiver)
    }
    
    func layerChange(_ layer: AuroraLiveLayer) {
        player.layer(layer: layer)
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
                        Picker(selection: $selectedLayer.onChange(layerChange), label: Text("choose a layer")) {
                            ForEach(layers, id: \.self) {
                                Text($0.displayText).tag($0)
                            }
                        }
                    }
                    
                    Text(verbatim: "current layer: \(player.currentLayer.displayText)").foregroundColor(.white)
                    Text(verbatim: "pkt lost: \(playerDelegateReceiver.pktLost)").foregroundColor(.white)
                    Text(verbatim: "bitrate: \(playerDelegateReceiver.bitrate) kb/s").foregroundColor(.white)
                    
                    ZStack(alignment: .bottom) {
                        if playerDelegateReceiver.loadError == nil {
                            SwiftUIVideoView($player.videoTrack, isRendering: $isRendering, layoutMode: .fit, debug: true)
                                .onAppear {
                                    if playbackId.isEmpty {
                                        return
                                    }
                                    
                                    if !loaded {
                                        loaded = true
                                        player.play(playbackId: playbackId, token: token.isEmpty ? nil : token)
                                    }
                                }
                                .onDisappear {
                                    if loaded {
                                        player.close()
                                        loaded = false
                                    }
                                    
                                    playerDelegateReceiver.loadError = nil
                                }
                            
                            if !isRendering {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            }
                        }  else {
                            Text(verbatim: "error: \(playerDelegateReceiver.loadError!.localizedDescription)").foregroundColor(.white)
                        }
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
