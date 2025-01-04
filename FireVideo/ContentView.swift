//
//  ContentView.swift
//  FireVideo
//
//  Created by Laly on 02/01/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var wsClient = WebSocketClient.instance
    
    var body: some View {
        VideoPlayerWithOverlay(
            videoName: "Fire-On",
            isDimmed: !wsClient.isFireOn
        )
        .onAppear {
            wsClient.sendText(route: "step1", data: "Application vidéo connectée")
        }
    }
}

#Preview {
    ContentView()
}
