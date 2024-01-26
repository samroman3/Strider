//
//  ItemFormatter.swift
//  myPedometer
//
//  Created by Sam Roman on 1/24/24.
//

import Foundation

let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    return formatter
}()

extension Date {
    func isToday() -> Bool {
        return Calendar.current.isDateInToday(self)
    }
}


