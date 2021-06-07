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
        }
    }
    
    init() {
        self.rewardCount = UserDefaults.standard.object(forKey: "rewardCount") as? Int ?? 0
    }
}
