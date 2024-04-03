//
//  Participant.swift
//  myPedometer
//
//  Created by Sam Roman on 3/19/24.
//

import Foundation
import CloudKit

struct ParticipantDetails: Identifiable, Equatable {
    let id: String
    let userName: String?
    let photoData: Data?
    var steps: Int
    
    init(user: User, recordId: String) {
        self.id = recordId
        self.userName = user.userName
        self.photoData = user.photoData
        self.steps = 0
    }
    
    init(id: String, userName: String?, photoData: Data?, steps: Int) {
            self.id = id
            self.userName = userName
            self.photoData = photoData
            self.steps = steps
        }
}

extension ParticipantDetails {
    func toCKRecord() -> CKRecord {
        //participant will have the same recordID as the User object it is init from 
        let recordId = CKRecord.ID(recordName: self.id)
        let record = CKRecord(recordType: "Participant", recordID: recordId)
        
        record["userName"] = self.userName ?? ""
        record["photoData"] = self.photoData
        record["steps"] = self.steps
        
        return record
    }
    
    static func fromCKRecord(_ record: CKRecord) -> ParticipantDetails? {
           guard let userName = record["userName"] as? String,
                 let steps = record["steps"] as? Int else {
               // These fields are essential; if they're missing, return nil
               return nil
           }
           
           // `photoData` can be nil if not set, so it's fine to directly try to cast it without a guard statement.
           let photoData = record["photoData"] as? Data
           let id = record.recordID.recordName

           return ParticipantDetails(id: id, userName: userName, photoData: photoData, steps: steps)
       }
}
