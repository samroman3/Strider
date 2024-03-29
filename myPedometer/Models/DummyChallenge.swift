//
//  DummyChallenge.swift
//  myPedometer
//
//  Created by Sam Roman on 3/24/24.
//

import Foundation

struct DummyChallenge: Identifiable {
    let id = UUID()
    var goalSteps: Int
    var currentSteps: [Int]
    var status: ChallengeStatus
    var participants: [String]
    var winner: Int?
}
