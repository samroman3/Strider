//
//  PedometerDataStore.swift
//  myPedometer
//
//  Created by Sam Roman on 1/24/24.
//
import Foundation
import CoreData

class PedometerDataStore: ObservableObject {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // Fetches or creates a DailyLog for a given date.
    func fetchOrCreateDailyLog(for date: Date, completion: @escaping (DailyLog) -> Void) {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let request: NSFetchRequest<DailyLog> = DailyLog.fetchRequest()
        request.predicate = NSPredicate(format: "date == %@", startOfDay as NSDate)

        do {
            let results = try context.fetch(request)
            if let existingLog = results.first {
                completion(existingLog)
            } else {
                let newLog = DailyLog(context: context)
                newLog.date = startOfDay
                completion(newLog)
            }
        } catch {
            print("Error fetching DailyLog: \(error)")
            let newLog = DailyLog(context: context)
            newLog.date = startOfDay
            completion(newLog)
        }
    }

    // Fetches the last seven days of data.
    
    func fetchLastSevenDaysData(completion: @escaping ([DailyLog]) -> Void) {
        var fetchedLogs = [DailyLog]()

        // Fetch today's log first
        let today = Calendar.current.startOfDay(for: Date())
        fetchOrCreateDailyLog(for: today) { todayLog in
            fetchedLogs.append(todayLog)

            // Fetch the previous six days
            for daysBack in 1..<7 {
                let date = Calendar.current.date(byAdding: .day, value: -daysBack, to: today)!
                self.fetchOrCreateDailyLog(for: date) { dailyLog in
                    fetchedLogs.append(dailyLog)

                    if fetchedLogs.count == 7 {
                        DispatchQueue.main.async {
                            // Sort the logs in descending order of dates
                            completion(fetchedLogs.sorted { $0.date! > $1.date! })
                        }
                    }
                }
            }
        }
    }


    // Saves changes to the context.
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
    
    
    
    func updateDailyLogWithFlights(ascended: Int32, descended: Int32, for date: Date) {
        fetchOrCreateDailyLog(for: date) { dailyLog in
            DispatchQueue.main.async {
                dailyLog.flightsAscended = ascended
                dailyLog.flightsDescended = descended
                self.saveContext()
            }
        }
    }
    
    // New method to update DailyLog with hourly steps data
    func updateDailyLogWithHourlySteps(hourlySteps: [Int], for date: Date) {
        fetchOrCreateDailyLog(for: date) { dailyLog in
            DispatchQueue.main.async {
                // Remove existing hourly step data
                if let existingSteps = dailyLog.hourlyStepData as? Set<HourlyStepData> {
                    existingSteps.forEach { dailyLog.removeFromHourlyStepData($0) }
                }
                
                // Add new hourly step data
                hourlySteps.enumerated().forEach { hour, steps in
                    let hourlyData = HourlyStepData(context: self.context)
                    hourlyData.hour = Int16(hour)
                    hourlyData.stepCount = Int32(steps)
                    hourlyData.date = date
                    dailyLog.addToHourlyStepData(hourlyData)
                }
                self.saveContext()
            }
        }
    }
}
