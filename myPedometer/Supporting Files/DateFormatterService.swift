//
//  DateFormatterService.swift
//  myPedometer
//
//  Created by Sam Roman on 1/27/24.
//

import Foundation

class DateFormatterService {
    
    static let shared = DateFormatterService()
    
    private init() {}
    
    private let dateFormatter = DateFormatter()
    
    func getItemFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }
    
    func format(date: Date, style: DateFormatter.Style) -> String {
        dateFormatter.dateStyle = style
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: date)
    }
    
    func formatHour(_ hour: Int) -> String {
        dateFormatter.dateFormat = "ha"
        guard let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) else {
            return ""
        }
        return dateFormatter.string(from: date)
    }
}
