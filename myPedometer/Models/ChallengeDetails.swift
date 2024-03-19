//
//  ChallengeDetails.swift
//  myPedometer
//
//  Created by Sam Roman on 3/18/24.
//

import Foundation

struct ChallengeDetails {
    var startTime: Date
    var endTime: Date
    var goalSteps: Int32
    var active: Bool
    var participants: [Participant]
    var recordId: String
}
