//
//  ContentView.swift
//  GuitarUtilities
//
//  Created by Yukai Chang on 2021/4/9.
//

import SwiftUI
import GoogleMobileAds

struct ContentView: View {
    @State var interstitial = InterstitialAd()
    let pub = NotificationCenter.default.publisher(for: Notification.getName(.tappingTab))
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 10) {
                RewardAdButton().frame(width: geo.frame(in: .local).width, height: geo.frame(in: .local).height / 20)
                TabView {
                    TunerView().tabItem {
                        Image(systemName: "tuningfork")
                        Text(NSLocalizedString("Tuner", comment: ""))
                    }.tag(1)
                    MetronomeView().tabItem {
                        Image(systemName: "metronome")
                        Text(NSLocalizedString("Metronome", comment: ""))
                    }.tag(2)
                }
            }
        }
        .onAppear {
            // init for new ad?
            interstitial = InterstitialAd()
            DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
                interstitial.showAd()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
