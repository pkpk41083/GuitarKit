//
//  UserDefaults.swift
//  GuitarKit
//
//  Created by Yukai Chang on 2021/6/1.
//

import Foundation
import Combine

class UserSettings: ObservableObject {
    @Published var rewardCount: Int {
        didSet {
            UserDefaults.standard.set(rewardCount, forKey: "rewardCount")
            if rewardCount >= 5 {
                isAdFree = true
            }
        }
    }
    @Published var isAdFree: Bool {
        didSet {
            UserDefaults.standard.set(isAdFree, forKey: "isAdFree")
        }
    }
    
    init() {
        self.rewardCount = UserDefaults.standard.object(forKey: "rewardCount") as? Int ?? 0
        self.isAdFree = UserDefaults.standard.object(forKey: "isAdFree") as? Bool ?? false
    }
}
