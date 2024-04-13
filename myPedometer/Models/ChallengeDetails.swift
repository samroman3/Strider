//
//  ChallengeDetails.swift
//  myPedometer
//
//  Created by Sam Roman on 3/18/24.
//

import Foundation
import CloudKit

struct ChallengeDetails: Identifiable {
    var id: String
    var startTime: Date
    var endTime: Date
    var goalSteps: Int32
    var status: String
    var recordId: String
    var winner: String?
    var creatorUserName: String?
    let creatorPhotoData: Data?
    var creatorSteps: Int?
    var creatorRecordID: String?
    var participantUserName: String?
    let participantPhotoData: Data?
    var participantSteps: Int?
    var participantRecordID: String?
    
    
    
}


struct PendingChallenge: Identifiable {
    var id: String
    let challengeDetails: ChallengeDetails
    let shareRecordID: String
}

