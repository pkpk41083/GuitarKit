//
//  TunerRecorder.swift
//  GuitarUtilities
//
//  Created by Yukai Chang on 2021/5/7.
//

import SwiftUI
import AudioKit
import AVFoundation

struct TunerData {
    var pitch: Float = 0.0
    var amplitude: Float = 0.0
    var noteNameWithSharps = "-"
    var noteNameWithFlats = "-"
    var noteNames = "-"
    var octave = 0
    var discrepancy: Float = 0.0
    var notePositionId: Int = 0
    var description = NSLocalizedString("Make some noise!", comment: "")
    var descriptionColor: Color = .white
    var statusColor: Color = .white
    var isLoading = false
}

class TunerConductor: ObservableObject {
    let engine = AudioEngine()
    var mic: AudioEngine.InputNode
    var tappableNode1: Fader
    var tappableNodeA: Fader
    var tappableNode2: Fader
    var tappableNodeB: Fader
    var tappableNode3: Fader
    var tappableNodeC: Fader
    var tracker: PitchTap!
    var silence: Fader

//    let noteFrequencies = [16.35, 17.32, 18.35, 19.45, 20.6, 21.83, 23.12, 24.5, 25.96, 27.5, 29.14, 30.87]
    let noteNamesWithSharps = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
    let noteNamesWithFlats = ["C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B"]
    
    let noteFrequencies = [16.35, 18.35, 20.6, 21.83, 24.5, 27.5, 30.87]
    let noteNames = ["C", "D", "E", "F", "G", "A", "B"]
    
    @Published var data = TunerData()

    func update(_ pitch: AUValue, _ amp: AUValue) {
        data.pitch = pitch
        data.amplitude = amp

        var frequency = pitch
        var scaleParam: Float = 0
        while frequency > Float(noteFrequencies[noteFrequencies.count - 1]) {
            frequency /= 2.0
            scaleParam += 1
        }
        while frequency < Float(noteFrequencies[0]) {
            frequency *= 2.0
            scaleParam -= 1
        }
        // change scaleParam from times to pow
        if scaleParam == 0 {
            scaleParam = 1
        } else {
            scaleParam = scaleParam > 0 ? pow(2, scaleParam) : 1 / pow(2, scaleParam)
        }

        var minDistance: Float = 10_000.0
        var index = 0
        var discrepancy: Float = 0

        for possibleIndex in 0 ..< noteFrequencies.count {
            let distance = fabsf(Float(noteFrequencies[possibleIndex]) - frequency)
            if distance < minDistance {
                index = possibleIndex
                minDistance = distance
                // estimate discrepancy
                discrepancy = pitch - (Float(noteFrequencies[possibleIndex]) * scaleParam)
            }
        }
        data.octave = Int(log2f(pitch / frequency))
//        data.noteNameWithSharps = amp > 0.1 ? "\(noteNamesWithSharps[index])" : "-"
//        data.noteNameWithFlats = amp > 0.1 ?  "\(noteNamesWithFlats[index])" : "-"
//        data.noteNames = amp > 0.1 ?  "\(noteNames[index])" : "-"
//        data.discrepancy = amp > 0.1 ? discrepancy : 0.0
        if amp > 0.2 {
            data.notePositionId = getNotePositionId(index: index, scaleParam: scaleParam)
            data.descriptionColor = data.discrepancy > 0 || data.discrepancy < 0 ? .orange : .green
            data.statusColor = abs(data.discrepancy * 15) > 10 ? .orange : .green
            data.description = data.statusColor == .green ?  NSLocalizedString("Great!", comment: "") : data.discrepancy > 0 ? NSLocalizedString("Loosen up!", comment: "") : NSLocalizedString("Tighten up!", comment: "")
            data.noteNames = "\(noteNames[index])"
            data.discrepancy = discrepancy
        } else {
            data.notePositionId = 0
            data.description = NSLocalizedString("Make some noise!", comment: "")
            data.descriptionColor = .white
            data.statusColor = .white
            data.noteNames = "-"
            data.discrepancy = 0
        }
    }

    init() {
        guard let input = engine.input else {
            fatalError()
        }

        mic = input
        tappableNode1 = Fader(mic)
        tappableNode2 = Fader(tappableNode1)
        tappableNode3 = Fader(tappableNode2)
        tappableNodeA = Fader(tappableNode3)
        tappableNodeB = Fader(tappableNodeA)
        tappableNodeC = Fader(tappableNodeB)
        silence = Fader(tappableNodeC, gain: 0)
        engine.output = silence

        tracker = PitchTap(mic) { pitch, amp in
            DispatchQueue.main.async {
                self.update(pitch[0], amp[0])
            }
        }
    }

    func start() {
        do {
            try engine.start()
            tracker.start()
        } catch let err {
            Log(err)
            print(err)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.start()
            }
        }
    }

    func stop() {
        engine.stop()
    }
    
    func resetData () {
        data.descriptionColor = .white
        data.statusColor = .white
        data.noteNames = "C"
        data.octave = 1
        data.notePositionId = 0
        data.description = NSLocalizedString("Make some noise!", comment: "")
    }
    
    func setAudioSessionCategory () {
        if AVAudioSession.sharedInstance().category != .playAndRecord {
            data.isLoading = true
            do {
                try AVAudioSession.sharedInstance().setActive(false)
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord)
                try AVAudioSession.sharedInstance().setActive(true)
                // no idea just wait
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                    self.start()
                    self.data.isLoading = false
                })
            } catch {
                print(error.localizedDescription)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.setAudioSessionCategory()
                }
            }
        }
    }
    
    func getNotePositionId (index: Int, scaleParam: Float) -> Int {
        var space: Double = 0
        
        if data.discrepancy > 0 && index < noteFrequencies.count - 1 {
            space = (noteFrequencies[index + 1] - noteFrequencies[index]) * Double(scaleParam)
        } else if data.discrepancy < 0 && index > 0 {
            space = (noteFrequencies[index] - noteFrequencies[index - 1]) * Double(scaleParam)
        } else {
            return 0
        }
        
        let pationId = lround(Double(abs(data.discrepancy)) * 10 / space)
        
        
        return data.discrepancy > 0 ? pationId : -pationId
    }
}
