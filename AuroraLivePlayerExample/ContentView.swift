//
//  ContentView.swift
//  AuroraLivePlayerExample
//
//  Created by retamia on 2023/9/12.
//

import SwiftUI

struct ContentView: View {
    // auroralive live demo playback id
    @State private var playbackId: String = "YTg0NjQ1ZWNhZmYxN2VmNjU5OTMyMjU0NmE3YzFkMzk"
    @State private var token: String = ""
    @State private var isShowingDetailView = false
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(destination: LiveView(playbackId: playbackId, token: token), isActive: $isShowingDetailView) {
                    EmptyView()
                }
                .foregroundColor(.green)
                .background(Color.yellow)
                VStack {
                    Spacer(minLength: 10)
                    TextField("enter playback id", text: $playbackId)
                        .keyboardType(.asciiCapable)
                        .autocorrectionDisabled(true)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 200)
                    TextField("enter token, optional", text: $token)
                        .keyboardType(.asciiCapable)
                        .autocorrectionDisabled(true)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 200)
                       
                    Button("play") {
                        if (!self.playbackId.isEmpty) {
                            self.isShowingDetailView = true
                        }
                    }
                    Spacer()
                }
                
                Spacer()
            }
            .navigationBarTitle("AuroraLive Player demo", displayMode: .inline)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
