//
//  FireVideoApp.swift
//  FireVideo
//
//  Created by Laly on 02/01/2025.
//
  
import SwiftUI
import AVKit

class WebSocketClient: ObservableObject {
    static let instance = WebSocketClient()
    private var webSocket: URLSessionWebSocketTask?
    @Published var isFireOn: Bool = false
    
    private init() {
        setupWebSocket()
    }
    
    private func setupWebSocket() {
        let url = URL(string: "ws://192.168.2.241:8080")! // A CHANGER !!!!!
        let session = URLSession(configuration: .default)
        webSocket = session.webSocketTask(with: url)
        webSocket?.resume()
        receiveMessage()
    }
    
    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    if text == "Feu allumé" {
                        DispatchQueue.main.async {
                            self?.isFireOn = true
                        }
                    }
                default:
                    break
                }
                self?.receiveMessage()
            case .failure(let error):
                print("WebSocket error: \(error)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self?.setupWebSocket()
                }
            }
        }
    }
    
    func sendText(route: String, data: String) {
        let message = ["route": route, "data": data]
        if let jsonData = try? JSONEncoder().encode(message),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            webSocket?.send(.string(jsonString)) { error in
                if let error = error {
                    print("Error sending message: \(error)")
                }
            }
        }
    }
}

struct VideoPlayerWithOverlay: View {
    let videoName: String
    let isDimmed: Bool
    
    var body: some View {
        ZStack {
            // Lecteur vidéo
            VideoPlayer(player: makeLoopingPlayer(for: videoName))
                .edgesIgnoringSafeArea(.all)
            
            // Voile noir
            Rectangle()
                .fill(Color.black)
                .opacity(isDimmed ? 0.8 : 0) // Opacité élevée quand dimmed, transparente sinon
                .animation(.easeInOut(duration: 1.0), value: isDimmed) // Animation douce
        }
    }
    
    private func makeLoopingPlayer(for videoName: String) -> AVPlayer {
        if let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") {
            print("URL vidéo trouvée : \(url)")
            let player = AVPlayer(url: url)
            
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player.currentItem,
                queue: .main) { _ in
                    player.seek(to: .zero)
                    player.play()
                }
            
            player.play()
            return player
        } else {
            print("❌ Erreur : Impossible de trouver la vidéo \(videoName).mp4")
            let dummy = URL(fileURLWithPath: "")
            return AVPlayer(url: dummy)
        }
    }
}

@main
struct FireVideoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
