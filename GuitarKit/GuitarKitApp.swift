//
//  GuitarUtilitiesApp.swift
//  GuitarUtilities
//
//  Created by Yukai Chang on 2021/4/9.
//

import SwiftUI
import GoogleMobileAds

@main
struct GuitarKitApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .onAppear {
                    // start google mobile ads service
                    GADMobileAds.sharedInstance().start(completionHandler: nil)
                }
        }
    }
}
