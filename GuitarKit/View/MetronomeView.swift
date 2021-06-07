//
//  MetronomeView.swift
//  GuitarUtilities
//
//  Created by Yukai Chang on 2021/5/22.
//

import SwiftUI
import AVFoundation
import UIKit

struct MetronomeView: View {
    @StateObject var conductor = MetronomeConductor()
    
    var body: some View {
        GeometryReader { geo in
            VStack() {
                Spacer()
                ZStack {
                    if conductor.data.isShowingAnimationShadow {
                        Circle()
                            .stroke(Color.white)
                            .scaleEffect(conductor.data.metronomeBtnAnimationAmount)
                            .opacity(Double(2 - conductor.data.metronomeBtnAnimationAmount))
                            .animation(
                                Animation.easeOut(duration: conductor.data.metronomeBtnAnimationDuration)
                                    .repeatForever(autoreverses: false)
                            )
                    }
                    Button {
                        conductor.handleMetronomeBtnTapped { handler in
                            withAnimation(.linear(duration: 0.2)) {
                                conductor.data.isShowingBPM.toggle()
                                conductor.data.isShowingCustomKeyboard = false
                            }
                            // call after animation complete
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                handler()
                            }
                        }
                    } label: {
                        ZStack() {
                            Circle()
                                .strokeBorder(Color.white, lineWidth: 1)
                                .background(Text(conductor.data.actionTitle.rawValue).foregroundColor(.white))
                        }
                    }
                }.frame(width: geo.frame(in: .local).maxX / 3, height: geo.frame(in: .local).maxX / 3)
                if conductor.data.isShowingBPM {
                    Button {
                        conductor.data.isShowingCustomKeyboard.toggle()
                    } label: {
                        Text("\(Int(conductor.data.bpm)) BPM")
                            .font(.largeTitle)
                    }.frame(width: geo.frame(in: .local).maxX, height: geo.frame(in: .local).maxX / 3)
                }
                Spacer()
                if conductor.data.isShowingCustomKeyboard {
                    CustomKeyboard().frame(width: geo.frame(in: .local).maxX, height: geo.frame(in: .local).maxY / 3)
                }
                Banner()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .environmentObject(conductor)
        .onAppear {
            // change selected index of tabView
            NotificationCenter.default.post(name: Notification.getName(.tappingTab), object: self, userInfo: ["selectedIndex" : 2])
        }
        .onDisappear {
            conductor.stopMetronome()
            conductor.resetData()
            // broadcast notification
            NotificationCenter.default.post(name: Notification.getName(.alreadyStopMetronome), object: self)
        }
    }
}

struct CustomKeyboard: View {
    @EnvironmentObject var conductor: MetronomeConductor
    
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                ForEach (0..<3) { index in
                    Button {
                        conductor.setBPM(index + 1)
                    } label: {
                        Text("\(index + 1)")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(hex: "#1C1C1E"))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            HStack(spacing: 10) {
                ForEach (3..<6) { index in
                    Button {
                        conductor.setBPM(index + 1)
                    } label: {
                        Text("\(index + 1)")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(hex: "#1C1C1E"))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            HStack(spacing: 10) {
                ForEach (6..<9) { index in
                    Button {
                        conductor.setBPM(index + 1)
                    } label: {
                        Text("\(index + 1)")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(hex: "#1C1C1E"))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            HStack(spacing: 10) {
                Button {
                    conductor.setBPM(nil)
                } label: {
                    ZStack() {
                        Rectangle()
                            .fill(Color(hex: "#1C1C1E"))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .cornerRadius(10)
                        Image(systemName: "delete.left").foregroundColor(.white)
                    }.frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                Button {
                    conductor.setBPM(0)
                } label: {
                    Text("0")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(hex: "#1C1C1E"))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                Button {
                    conductor.checkBPM()
                    conductor.data.isShowingCustomKeyboard = false
                } label: {
                    Text("Done")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(hex: "#1C1C1E"))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }.background(Color(hex: "#0E0E10"))
    }
}
