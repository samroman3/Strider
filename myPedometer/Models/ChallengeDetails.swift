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
    var participants: [Participant]
    var recordId: String
}
extension ChallengeDetails {
    
    static func fromCKRecord(_ record: CKRecord) -> ChallengeDetails? {
        guard let startTime = record["startTime"] as? Date,
              let endTime = record["endTime"] as? Date,
              let goalSteps = record["goalSteps"] as? Int,
              let status = record["status"] as? String,
              let participants = record["participants"] as? [Participant],
              let recordId = record["recordId"] as? String
        else {
            return nil
        }
            
        
        return ChallengeDetails(id: recordId, startTime: startTime, endTime: endTime, goalSteps: Int32(goalSteps), status: status, participants: participants, recordId: recordId)
    }
    
}
