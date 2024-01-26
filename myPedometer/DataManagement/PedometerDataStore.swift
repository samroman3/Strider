//
//  PedometerDataStore.swift
//  myPedometer
//
//  Created by Sam Roman on 1/24/24.
//
import Foundation
import CoreData
import CoreMotion

class PedometerDataStore: ObservableObject {
    private let context: NSManagedObjectContext
    let pedometerManager: PedometerDataProvider

    init(context: NSManagedObjectContext, pedometerManager: PedometerDataProvider) {
        self.context = context
        self.pedometerManager = pedometerManager
    }

    func storeDailyGoal(_ goal: Int) {
        UserDefaults.standard.set(goal, forKey: "dailyStepGoal")
    }

    func retrieveDailyGoal() -> Int {
        UserDefaults.standard.integer(forKey: "dailyStepGoal")
    }
    
    //DetailView Methods
    // Fetches or creates a DailyLog, then updates it with hourly steps, flights, and goal status.
    func getDetailData(for date: Date, completion: @escaping (DetailData) -> Void) {
        let startOfDay = Calendar.current.startOfDay(for: date)

        fetchOrCreateDailyLog(for: date) { [weak self] dailyLog in
            guard let self = self else { return }
            
            // Retrieve the daily goal from user defaults or set a default value
            let dailyStepGoal = UserDefaults.standard.integer(forKey: "dailyStepGoal") == 0 ? 1000 : UserDefaults.standard.integer(forKey: "dailyStepGoal")
            
            // If it's not today, we can use the data already in the dailyLog
            if !Calendar.current.isDateInToday(date) {
                let existingHourlySteps = (dailyLog.hourlyStepData as? Set<HourlyStepData>)?.sorted { $0.hour < $1.hour }.map {
                    HourlySteps(hour: Int($0.hour), steps: Int($0.stepCount))
                } ?? []
                let detailData = DetailData(
                    hourlySteps: existingHourlySteps,
                    flightsAscended: Int(dailyLog.flightsAscended),
                    flightsDescended: Int(dailyLog.flightsDescended),
                    goalAchievementStatus: dailyLog.totalSteps >= dailyStepGoal ? .achieved : .notAchieved,
                    dailySteps: Int(dailyLog.totalSteps),
                    dailyGoal: dailyStepGoal
                )
                DispatchQueue.main.async {
                    completion(detailData)
                }
            } else {
                // For today's data, fetch the latest from the pedometer
                self.fetchTodayData(dailyLog: dailyLog, dailyGoal: dailyStepGoal, completion: completion)
            }
        }
    }
        
        // Fetches today's data including steps and flights from the pedometer
    private func fetchTodayData(dailyLog: DailyLog, dailyGoal: Int, completion: @escaping (DetailData) -> Void) {
        let today = Calendar.current.startOfDay(for: Date())
        
        // Fetch today's total steps and flights data
        pedometerManager.fetchSteps(for: today) { [weak self] steps, error in
            guard let self = self, error == nil else {
                print("Error fetching steps: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            self.pedometerManager.fetchFlights(for: today) { ascended, descended, error in
                guard error == nil else {
                    print("Error fetching flights: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                // Fetch hourly step data
                self.pedometerManager.fetchHourlyStepData(for: today) { hourlyData in
                    // Map hourly data to HourlySteps objects
                    let hourlySteps = hourlyData.enumerated().map { HourlySteps(hour: $0.offset, steps: $0.element) }
                    
                    // Create the DetailData object
                    let detailData = DetailData(
                        hourlySteps: hourlySteps,
                        flightsAscended: Int(ascended),
                        flightsDescended: Int(descended),
                        goalAchievementStatus: steps >= dailyGoal ? .achieved : .notAchieved,
                        dailySteps: steps,
                        dailyGoal: dailyGoal
                    )

                    // Call the completion handler with the detail data
                    DispatchQueue.main.async {
                        completion(detailData)
                    }

                    // Update the DailyLog object in CoreData with the new data
                    dailyLog.totalSteps = Int32(steps)
                    dailyLog.flightsAscended = Int32(ascended)
                    dailyLog.flightsDescended = Int32(descended)
                    hourlySteps.forEach { hourlyStep in
                        let hourlyStepData = HourlyStepData(context: self.context)
                        hourlyStepData.hour = Int16(hourlyStep.hour)
                        hourlyStepData.stepCount = Int32(hourlyStep.steps)
                        dailyLog.addToHourlyStepData(hourlyStepData)
                    }
                    self.saveContext()
                }
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

    func fetchLastSevenDaysData(completion: @escaping ([DailyLog]) -> Void) {
        var fetchedLogs = [DailyLog]()

        for daysBack in 0..<7 {
            let date = Calendar.current.date(byAdding: .day, value: -daysBack, to: Date())!
            fetchOrCreateDailyLog(for: date) { dailyLog in
                if self.needsUpdating(log: dailyLog, for: date) {
                    self.updateDailyLog(dailyLog, for: date) { updatedLog in
                        fetchedLogs.append(updatedLog)
                        if fetchedLogs.count == 7 {
                            completion(fetchedLogs)
                        }
                    }
                } else {
                    fetchedLogs.append(dailyLog)
                    if fetchedLogs.count == 7 {
                        completion(fetchedLogs)
                    }
                }
            }
        }
    }

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
    
    func storeCurrentDayData(stepCount: Int, for date: Date) {
        fetchOrCreateDailyLog(for: date) { dailyLog in
            DispatchQueue.main.async {
                dailyLog.totalSteps = Int32(stepCount)
                self.saveContext()
            }
        }
    }

    private func needsUpdating(log: DailyLog, for date: Date) -> Bool {
        return log.hourlyStepData == nil || log.flightsAscended == 0 || log.flightsDescended == 0
    }

    private func updateDailyLog(_ log: DailyLog, for date: Date, completion: @escaping (DailyLog) -> Void) {
        let group = DispatchGroup()

        if log.flightsAscended == 0 || log.flightsDescended == 0 {
            group.enter()
            pedometerManager.fetchFlights(for: date) { ascended, descended, error in
                guard error == nil else {
                    print("Error fetching flights: \(error!)")
                    group.leave()
                    return
                }

                log.flightsAscended = ascended
                log.flightsDescended = descended
                group.leave()
            }
        }

        group.enter()
        pedometerManager.fetchHourlyStepData(for: date) { hourlySteps in
            if let existingSteps = log.hourlyStepData as? Set<HourlyStepData> {
                existingSteps.forEach { log.removeFromHourlyStepData($0) }
            }

            hourlySteps.enumerated().forEach { hour, steps in
                let hourlyData = HourlyStepData(context: self.context)
                hourlyData.hour = Int16(hour)
                hourlyData.stepCount = Int32(steps)
                hourlyData.date = date
                log.addToHourlyStepData(hourlyData)
            }
            group.leave()
        }

        group.notify(queue: DispatchQueue.main) {
            self.saveContext()
            completion(log)
        }
    }
    
    

    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
}
