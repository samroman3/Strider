//
//  UserFriendlyError.swift
//  myPedometer
//
//  Created by Sam Roman on 1/29/24.
//

import Foundation
enum UserFriendlyError: Identifiable {
    var id: String { localizedMessage }
    
    case custom(message: String)
    case defaultError

    var localizedMessage: String {
        switch self {
        case .custom(let message):
            return message
        case .defaultError:
            return "An unexpected error occurred. Please try again later."
        }
    }

    init(error: Error) {
        self = .custom(message: error.localizedDescription)
    }
}
