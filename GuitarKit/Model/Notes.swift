//
//  Notes.swift
//  GuitarUtilities
//
//  Created by Yukai Chang on 2021/5/19.
//

import SwiftUI

struct NoteData {
    var notes = [String]()
}

class Notes: ObservableObject {
    @Published var data = NoteData()
    
    init() {
        updateNotes()
    }
    
    func updateNotes () {
        let normalNotes = ["C", "D", "E", "F", "G", "A", "B"]
        var octave = 1
        
        while octave <= 8 {
            for note in normalNotes {
                data.notes.append("\(note)\(octave)")
            }
            octave += 1
        }
        // add space at starting and ending
        data.notes.insert("", at: 0)
        data.notes.append("")
    }
    
    func getScaleRate (_ midX: CGFloat) -> CGFloat {
        let space = UIScreen.width / 3 // space between notes
        let centerX = UIScreen.width / 2
        var rate = 1 - abs(centerX - midX) / space
        
        if rate > 1 {
            rate = 1
        } else if rate < 0 {
            rate = 0
        }
        
        return rate + 1
    }
}
