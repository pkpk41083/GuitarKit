//
//  AdMobViews.swift
//  GuitarKit
//
//  Created by Yukai Chang on 2021/5/31.
//

import SwiftUI
import GoogleMobileAds
import UIKit

final private class BannerVC: UIViewControllerRepresentable  {

    func makeUIViewController(context: Context) -> UIViewController {
        let view = GADBannerView(adSize: kGADAdSizeBanner)
        let viewController = UIViewController()
        
        view.adUnitID = "ca-app-pub-1764411444589029/5309152259" // "ca-app-pub-1764411444589029/5309152259"
        view.rootViewController = viewController
        viewController.view.addSubview(view)
        viewController.view.frame = CGRect(origin: .zero, size: kGADAdSizeBanner.size)
        view.load(GADRequest())

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
}

struct Banner: View{
    var body: some View{
        HStack{
            Spacer()
            BannerVC().frame(width: 320, height: 50, alignment: .center)
            Spacer()
        }
    }
}

final class InterstitialAd: NSObject {
    var interstitial: GADInterstitialAd?
    
    func showAd () {
        // init ad
        GADInterstitialAd.load(withAdUnitID: "ca-app-pub-1764411444589029/9220477105", request: GADRequest()) { ad, err in
            guard err == nil else {
                print(err?.localizedDescription ?? "")
                return
            }
            self.interstitial = ad
            
            // show ad
            if let root = UIApplication.shared.windows.first?.rootViewController {
                self.interstitial?.present(fromRootViewController: root)
            }
        }
    }
}

final class RewardAd: NSObject {
    var reward: GADRewardedAd?
    var rewardFunction: (() -> Void)? = nil
    
    func showAd (rewardFunction: @escaping () -> Void) {
        // init ad
        GADRewardedAd.load(withAdUnitID: "ca-app-pub-1764411444589029/9328288315", request: GADRequest()) { ad, err in
            guard err == nil else {
                print(err?.localizedDescription ?? "")
                return
            }
            self.reward = ad
            
            // show ad
            if let root = UIApplication.shared.windows.first?.rootViewController {
                self.reward?.present(fromRootViewController: root, userDidEarnRewardHandler: {
                    rewardFunction()
                })
            }
        }
    }
}


struct RewardAdButton: View {
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var adData: AdData
    @State var rewardAd = RewardAd()
    
    var body: some View {
        GeometryReader { geo in
            HStack() {
                Spacer()
                if userSettings.rewardCount >= 5 {
                    HStack() {
                        Image(systemName: "star.circle").foregroundColor(.yellow)
                        Text("ad-free").foregroundColor(.yellow)
                    }
                } else {
                    Button {
                        adData.rewardAdIsloading = true
                        rewardAd.showAd {
                            adData.rewardAdIsloading = false
                            userSettings.rewardCount += 1
                        }
                    } label: {
                        if adData.rewardAdIsloading {
                            ProgressView()
                        } else {
                            Text("ad-free(\(userSettings.rewardCount)/5)")
                        }
                    }
                    .frame(width: geo.frame(in: .local).maxX / 3, height: geo.frame(in: .local).height)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [Color(hex: "004D80"), Color(hex: "0076BA")]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
    }
}
