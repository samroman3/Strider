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
    
    func longDateItemFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }
    
    func shortItemFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
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
    
    func relativeDateTimeFormatter(date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
                dateFormatter.dateStyle = .none
                dateFormatter.timeStyle = .short
                return "Today \n \(dateFormatter.string(from: date))"
        } else if Calendar.current.isDateInTomorrow(date) {
                return "Tomorrow \n \(dateFormatter.string(from: date))"
            } else {
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .short
                return dateFormatter.string(from: date)
            }
        }
    
    func relativeTimeLeftFormatter(date: Date) -> String {
           let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day], from: now, to: date)
           
        if Calendar.current.isDateInToday(date) {
               if let hour = components.hour, let minute = components.minute, hour == 0 {
                   return "\(minute) minutes left"
               } else if let hour = components.hour {
                   return "\(hour) hours left"
               }
        } else if Calendar.current.isDateInTomorrow(date) {
               return "Tomorrow  \n \(dateFormatter.string(from: date))"
           } else if let day = components.day, day <= 7 {
               return "\(day) days left"
           }
           dateFormatter.dateStyle = .medium
           dateFormatter.timeStyle = .none
           return dateFormatter.string(from: date)
       }

    // Helper function to create dates easily
    func createDate(dayOffset: Int, hour: Int, minute: Int) -> Date? {
        var dateComponents = DateComponents()
        dateComponents.day = dayOffset
        dateComponents.hour = hour
        dateComponents.minute = minute
        return Calendar.current.date(byAdding: dateComponents, to: Date())
    }
}
