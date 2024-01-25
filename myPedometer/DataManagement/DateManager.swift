//
//  WeeklyLogManager.swift
//  myPedometer
//
//  Created by Sam Roman on 1/24/24.
//

import Foundation
import CoreData
import CoreMotion

class DateManager: ObservableObject {
    @Published var selectedDate: Date
    @Published var dailyLogs: [DailyLog] = []
    private var context: NSManagedObjectContext

    init(context: NSManagedObjectContext, initialDate: Date = Date()) {
        self.context = context
        self.selectedDate = initialDate
        fetchDataForWeekOf(date: initialDate)
    }

    // Call this method whenever the selected date changes or when the steps data has been updated.
    func refreshData() {
        fetchDataForWeekOf(date: selectedDate)
    }

    func updateSelectedDate(newDate: Date) {
        selectedDate = newDate
        fetchDataForWeekOf(date: newDate)
    }

    func fetchDataForWeekOf(date: Date) {
        var calendar = Calendar.current
        calendar.timeZone = NSTimeZone.local

        // Get the start of the week
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) ?? date
        
        // Fetch step data for the week
        let fetchRequest: NSFetchRequest<DailyLog> = DailyLog.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "(date >= %@) AND (date < %@)",
                                             startOfWeek as NSDate,
                                             calendar.date(byAdding: .day, value: 7, to: startOfWeek)! as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]

        do {
            dailyLogs = try context.fetch(fetchRequest)
        } catch {
            print("Error fetching steps data for the week: \(error)")
        }
    }
    // For example: total steps in the week, average steps per day, etc.

    private func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
}
