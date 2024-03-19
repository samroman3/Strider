//
//  Participant.swift
//  myPedometer
//
//  Created by Sam Roman on 3/19/24.
//

import Foundation
import CloudKit

struct Participant: Identifiable {
    let id: String
    let userName: String?
    let photoData: Data?
    var steps: Int
    
    init(user: User) {
        self.id = user.recordID ?? ""
        self.userName = user.userName
        self.photoData = user.photoData
        self.steps = 0
    }
}

extension Participant {
    func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: self.id)
        let record = CKRecord(recordType: "Participant", recordID: recordID)
        
        record["userName"] = self.userName ?? ""
        record["photoData"] = self.photoData
        record["steps"] = self.steps
        // Note: Not necessary to save the recordID in the record itself, as it's already the unique identifier of the record.
        
        return record
    }
}
