//
//  TunerView.swift
//  GuitarUtilities
//
//  Created by Yukai Chang on 2021/4/9.
//

import SwiftUI
import AVFoundation
import GoogleMobileAds

struct TunerView: View {
    @StateObject var conductor = TunerConductor()
    let pub = NotificationCenter.default.publisher(for: Notification.getName(.alreadyStopMetronome))
    
    var body: some View {
        GeometryReader { geo in
            ZStack() {
                VStack(spacing: 0) {
                    PitchDashBoard().padding(10)
                    NoteScrollView()
                    Banner()
                }
                if conductor.data.isLoading {
                    LoadingView().frame(width: geo.frame(in: .local).maxX / 4, height: geo.frame(in: .local).maxX / 4)
                }
            }
        }
        .environmentObject(conductor)
        .onAppear {
            if AVAudioSession.sharedInstance().category != .playback {
                conductor.start()
            }
        }
        .onDisappear {
            conductor.stop()
        }
        .onReceive(pub, perform: { _ in
            // change AVAudioSession category
            conductor.setAudioSessionCategory()
        })
    }
}

// MARK: - pitch dash board
struct PitchDashBoard: View {
    struct ArcParams {
        var startAngle: Double
        var endAngle: Double
    }
    @EnvironmentObject var conductor: TunerConductor
    
    func getArcParams () -> ArcParams {
        var startAngle: Double!
        var endAngle: Double!
        
        if conductor.data.discrepancy > 0 {
            endAngle = 270
            startAngle = 270 + Double(conductor.data.discrepancy * 15)
            if startAngle > 345 {
                startAngle = 345
            }
        } else if conductor.data.discrepancy < 0 {
            startAngle = 270
            endAngle = 270 + Double(conductor.data.discrepancy * 15)
            if endAngle < 195 {
                endAngle = 195
            }
        } else {
            startAngle = 270
            endAngle = 270
        }
        
        return ArcParams(startAngle: startAngle, endAngle: endAngle)
    }
    
    var body: some View {
        GeometryReader { geo in
            // pitch discrepancy view(sector)
            VStack(spacing: 0) {
                ZStack() {
                    Path() { path in
                        let center = CGPoint(x: geo.frame(in: .local).midX, y: geo.frame(in: .local).midY)
                        let radius = geo.frame(in: .local).getShorterSide() / 2
                        path.move(to: center)
                        path.addArc(center: center, radius: radius, startAngle: .degrees(getArcParams().startAngle), endAngle: .degrees(getArcParams().endAngle), clockwise: true)
                    }
                    .fill(conductor.data.statusColor)
                    .opacity(0.4)
                    Curve(geoRect: geo.frame(in: .local), radius: geo.frame(in: .local).getShorterSide() / 2).fill(Color.white)
                    // add a cover view to block partial pitch discrepancy view
                    Circle()
                        .fill(Color.black)
                        .frame(width: geo.frame(in: .local).getShorterSide() / 3, height: geo.frame(in: .local).getShorterSide() / 3)
                        .position(x: geo.frame(in: .local).midX, y: geo.frame(in: .local).midY)
                    Curve(geoRect: geo.frame(in: .local), radius: geo.frame(in: .local).getShorterSide() / 6).fill(Color.white)
                    Text(conductor.data.noteNames)
                        .frame(width: geo.frame(in: .local).getShorterSide() / 3, height: geo.frame(in: .local).getShorterSide() / 3)
                        .position(x: geo.frame(in: .local).midX, y: geo.frame(in: .local).midY)
                        .font(.system(size: geo.frame(in: .local).getShorterSide() / 3 - 20))
                        .foregroundColor(conductor.data.statusColor)
                }
                HStack() {
                    Spacer()
                    Text(conductor.data.description)
                        .foregroundColor(conductor.data.descriptionColor)
                        .font(.title)
                        .fontWeight(.heavy)
                    Spacer()
                }.frame(width: geo.frame(in: .local).maxX, height: geo.frame(in: .local).midY - (geo.frame(in: .local).getShorterSide() / 6))
            }
        }
    }
}

struct Curve: Shape {
    enum CurveType {
        case curve
        case sector
    }
    var geoRect: CGRect
    var radius: CGFloat
    func path (in rect: CGRect) -> Path {
        var path = Path()
        
        path.addArc(center: CGPoint(x: geoRect.midX, y: geoRect.midY), radius: radius, startAngle: .degrees(345), endAngle: .degrees(195), clockwise: true)

        return path.strokedPath(.init(lineWidth: 5))
    }
}

// MARK: - note scrollView
struct NoteScrollView: View {
    @StateObject var notes = Notes()
    @EnvironmentObject var conductor: TunerConductor
    
    var body: some View {
        VStack() {
            Image(systemName: "arrowtriangle.down.fill")
            GeometryReader { fullView in
                ScrollView(.horizontal, showsIndicators: false) {
                    ScrollViewReader { value in
                        HStack(spacing: 0) {
                            ForEach (0..<notes.data.notes.count) { index in
                                GeometryReader { geo in
                                    VStack(spacing: 0) {
                                        CalibrationView(noteName: notes.data.notes[index], alignment: .top).frame(maxWidth: .infinity, maxHeight: 20)
                                        Text(notes.data.notes[index])
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                            .scaleEffect(notes.getScaleRate(geo.frame(in: .global).midX))
                                            .font(.largeTitle)
                                            .animation(.linear)
                                        CalibrationView(noteName: notes.data.notes[index], alignment: .bottom).frame(maxWidth: .infinity, maxHeight: 20)
                                    }
                                }.frame(width: fullView.frame(in: .local).maxX / 3, height: fullView.frame(in: .local).maxY)
                            }
                        }.onChange(of: conductor.data.discrepancy, perform: { newValue in
                            // scrolling
                            guard conductor.data.noteNames != "-", conductor.data.octave > 0 else { return }
                            
                            let id = "\(conductor.data.noteNames)\(conductor.data.octave)_\(conductor.data.notePositionId)"
                            
                            value.scrollTo(id, anchor: .center)
                        })
                    }
                }.disabled(true)
            }
            Image(systemName: "arrowtriangle.up.fill")
        }
    }
}

struct CalibrationView: View {
    var noteName: String = ""
    var alignment: VerticalAlignment = .top
    
    init(noteName: String, alignment: VerticalAlignment) {
        self.noteName = noteName
        self.alignment = alignment
    }
    
    var body: some View {
        HStack(alignment: alignment, spacing: 0) {
            if noteName != "" {
                ForEach (0..<10) { spaceIndex in
                    if spaceIndex == 0 {
                        Rectangle()
                            .fill(noteName == "C1" ? Color.white : Color.clear)
                            .frame(width: 1, height: spaceIndex == 4 ? 20 : 10)
                            .id("\(noteName)_\(spaceIndex - 5)")
                    }
                    Spacer()
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 1, height: spaceIndex == 4 ? 20 : 10)
                        .id("\(noteName)_\(spaceIndex - 4)")
                }
            }
        }
    }
}

// MARK: - loading view
struct LoadingView: View {
    var body: some View {
        ZStack() {
            Text("")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(hex: "#1C1C1E"))
            ProgressView().foregroundColor(.white)
        }.cornerRadius(10)
    }
}
