//
//  File.swift
//  GuitarUtilities
//
//  Created by Yukai Chang on 2021/5/22.
//

import AVFoundation

struct MetronomeData {
    enum ActionTitle: String {
        case start = "start"
        case stop = "stop"
    }
    
    var playerIndex = 0
    var players = [AVAudioPlayer]()
    var currentPlayer = AVAudioPlayer()
    var actionTitle: ActionTitle = .start
    var bpm: TimeInterval = 100
    var metronomeTimer: Timer?
    var isShowingBPM = true
    var isShowingCustomKeyboard = false
    var isShowingAnimationShadow = false
    var metronomeBtnAnimationAmount: CGFloat = 1
    var metronomeBtnAnimationDuration: Double = 1
}

class MetronomeConductor: ObservableObject {
    typealias animationHandler = (@escaping () -> Void) -> Void
    @Published var data = MetronomeData()
    
    init() {
        guard let beat1URL = Bundle.main.url(forResource: "beat1", withExtension: "m4a"),
           let beat2URL = Bundle.main.url(forResource: "beat2", withExtension: "m4a") else {
            return
        }
        
        do {
            let player1 = try AVAudioPlayer(contentsOf: beat1URL)
            let player2 = try AVAudioPlayer(contentsOf: beat2URL)
            data.players = [player1, player2]
        } catch {
            data.players = [AVAudioPlayer()]
            print(error.localizedDescription)
        }
        data.currentPlayer = data.players[data.playerIndex]
    }
    
    func changePlayer () {
        data.playerIndex = data.players.count - 1 < data.playerIndex + 1 ? 0 : data.playerIndex + 1
        data.currentPlayer = data.players[data.playerIndex]
    }
    
    func resetData () {
        // reset player
        data.playerIndex = 0
        data.currentPlayer = data.players[data.playerIndex]
        // reset bpm
        data.bpm = 100
        // reset view-showing flag
        data.isShowingBPM = true
        data.isShowingCustomKeyboard = false
        // reset metronome button title
        data.actionTitle = .start
    }
    
    func handleMetronomeBtnTapped (animationHandler: @escaping animationHandler) {
        // call for acting animation
        animationHandler {
            // set data
            switch self.data.actionTitle {
            case .start:
                self.data.actionTitle = .stop
                self.startMetronome {
                    // set animation params
                    self.data.isShowingAnimationShadow = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 60 / self.data.bpm) {
                        self.data.metronomeBtnAnimationAmount = 2
                        self.data.metronomeBtnAnimationDuration = 60 / self.data.bpm
                    }
                }
            case .stop:
                self.data.metronomeBtnAnimationAmount = 1
                self.data.actionTitle = .start
                self.stopMetronome()
            }
        }
    }
    
    func startMetronome (handler: () -> Void) {
        do {
            try AVAudioSession.sharedInstance().setActive(false)
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            data.metronomeTimer = Timer.scheduledTimer(withTimeInterval: 60 / data.bpm, repeats: true) { _ in
                self.data.currentPlayer.play()
                self.changePlayer()
            }
            // set animation params
            handler()
        } catch {
            print(error.localizedDescription)
            // calling again
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.startMetronome {
                    // set animation params
                    self.data.isShowingAnimationShadow = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 60 / self.data.bpm) {
                        self.data.metronomeBtnAnimationAmount = 2
                        self.data.metronomeBtnAnimationDuration = 60 / self.data.bpm
                    }
                }
            }
        }
    }
    
    func stopMetronome () {
        data.metronomeTimer?.invalidate()
        data.metronomeTimer = nil
        data.currentPlayer.stop()
        // set animation params
        data.isShowingAnimationShadow = false
        data.metronomeBtnAnimationAmount = 1
        data.metronomeBtnAnimationDuration = 0
    }
    
    func setBPM (_ num: Int?) {
        var bpmString = String(Int(data.bpm))
        // backspace
        guard let num = num else {
            if bpmString.count > 0 {
                bpmString = String(Array(bpmString).dropLast())
                data.bpm = TimeInterval(bpmString) ?? 0
            }
            
            return
        }
        
        if bpmString.count >= 3 {
            data.bpm = TimeInterval(String(num)) ?? 0
        } else {
            data.bpm = TimeInterval(bpmString + String(num)) ?? 0
        }
        // bpm must under 200
        guard data.bpm <= 200 else {
            data.bpm = 200
            return
        }
    }
    
    func checkBPM () {
        // bpm must under 200
        guard data.bpm <= 200 else {
            data.bpm = 200
            return
        }
        // bpm must above 0
        guard data.bpm > 0 else {
            data.bpm = 100
            return
        }
    }
}
