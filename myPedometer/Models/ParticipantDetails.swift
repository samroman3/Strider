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
    var steps: Int?
    
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
