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
    private var isConnected = false
    
    private init() {
        setupWebSocket()
    }
    
    private func setupWebSocket() {
        let url = URL(string: "ws://192.168.10.31:8080/step1-Feu")!
        let session = URLSession(configuration: .default)
        webSocket = session.webSocketTask(with: url)
        
        // Ping périodique pour maintenir la connexion
        startPingTimer()
        
        webSocket?.resume()
        isConnected = true
        print("🌐 WebSocket initialisé")
        sendText(route: "step1-Feu", text:"connect")
        
        // Démarrer l'écoute continue
        receiveMessage()
    }
    
    private func startPingTimer() {
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }
    
    private func sendPing() {
        webSocket?.sendPing { error in
            if let error = error {
                print("❌ Erreur de ping: \(error)")
                self.handleDisconnection()
            }
        }
    }
    
    private func handleDisconnection() {
        guard isConnected else { return }
        isConnected = false
        
        // Tentative de reconnexion
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            print("🔄 Tentative de reconnexion...")
            self?.setupWebSocket()
        }
    }
    
    private func receiveMessage() {
        guard isConnected else { return }
        
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                // Traiter le message
                switch message {
                case .string(let text):
                    print("📩 Message reçu: \(text)")
                    DispatchQueue.main.async {
                        if text == "App - Fire On" {
                            self?.isFireOn = true
                            print("🔥 Feu allumé")
                        } else if text == "Feu éteint" {
                            self?.isFireOn = false
                        } else if text == "ping" {
                            self?.sendText(route: "step1-Feu", text: "Fire video pong")
                       }
                    }
                case .data(let data):
                    print("📩 Données reçues: \(data)")
                @unknown default:
                    break
                }
                
                // Continuer l'écoute
                self?.receiveMessage()
                
            case .failure(let error):
                print("❌ Erreur WebSocket: \(error)")
                self?.handleDisconnection()
            }
        }
    }
    
    func sendText(route: String, text: String) {
        let message = text
        if let jsonData = try? JSONEncoder().encode(message),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            webSocket?.send(.string(jsonString)) { [weak self] error in
                if let error = error {
                    print("❌ Erreur d'envoi: \(error)")
                    self?.handleDisconnection()
                }
            }
        }
    }
    
    deinit {
        webSocket?.cancel(with: .normalClosure, reason: nil)
    }
}

struct VideoPlayerWithOverlay: View {
    let videoName: String
    let isDimmed: Bool
    private let player: AVPlayer
    
    init(videoName: String, isDimmed: Bool) {
        self.videoName = videoName
        self.isDimmed = isDimmed
        self.player = VideoPlayerWithOverlay.makeLoopingPlayer(for: videoName)
        // Définir le volume initial à 0
        self.player.volume = 0
    }
    
    var body: some View {
        ZStack {
            // Utiliser le player créé dans init au lieu d'en créer un nouveau
            VideoPlayer(player: player)
                .edgesIgnoringSafeArea(.all)
                .onChange(of: isDimmed) { newValue in
                    player.volume = newValue ? 0 : 1
                }
            
            Rectangle()
                .fill(Color.black)
                .opacity(isDimmed ? 0.8 : 0)
                .animation(.easeInOut(duration: 1.0), value: isDimmed)
        }
    }
    
    // Déplacé en méthode statique pour pouvoir l'utiliser dans init
    private static func makeLoopingPlayer(for videoName: String) -> AVPlayer {
        if let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") {
            let asset = AVAsset(url: url)
            let playerItem = AVPlayerItem(asset: asset)
            let player = AVPlayer(playerItem: playerItem)
            
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: playerItem, // Changé de player.currentItem à playerItem
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
