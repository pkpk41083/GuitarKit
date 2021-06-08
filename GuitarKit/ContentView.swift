//
//  ContentView.swift
//  GuitarUtilities
//
//  Created by Yukai Chang on 2021/4/9.
//

import SwiftUI
import GoogleMobileAds

struct ContentView: View {
    @StateObject var userSettings = UserSettings()
    @StateObject var adData = AdData()
    @State var interstitial = InterstitialAd()
    
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
            if !userSettings.isAdFree {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    if !adData.rewardAdIsloading {
                        interstitial.showAd()
                    }
                }
            }
        }
        .environmentObject(userSettings)
        .environmentObject(adData)
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
