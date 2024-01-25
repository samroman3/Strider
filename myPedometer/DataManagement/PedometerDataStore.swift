//
//  PedometerDataStore.swift
//  myPedometer
//
//  Created by Sam Roman on 1/24/24.
//

import Foundation
import CoreMotion
import CoreData

class PedometerDataStore: ObservableObject {
    private let context: NSManagedObjectContext
    let pedometerManager: PedometerManager

    init(context: NSManagedObjectContext, pedometerManager: PedometerManager) {
        self.context = context
        self.pedometerManager = pedometerManager
    }

    // Fetch last seven days of step data
    func fetchLastSevenDaysData() {
        for daysBack in 0..<7 {
            let date = Calendar.current.date(byAdding: .day, value: -daysBack, to: Date())!
            fetchOrCreateDailyLog(for: date) { dailyLog in
                if dailyLog.totalSteps == 0 {
                    // If steps are not recorded, query the pedometer
                    self.pedometerManager.fetchSteps(for: date) { steps, error in
                        guard error == nil else {
                            print("Error fetching steps: \(error!)")
                            return
                        }

                        DispatchQueue.main.async {
                            dailyLog.totalSteps = Int32(steps)
                            self.saveContext()
                        }
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
            // Create a new log if fetch fails
            let newLog = DailyLog(context: context)
            newLog.date = startOfDay
            completion(newLog)
        }
    }

    // Save any changes to the context
     func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
    
    func storeCurrentDayData() {
        let today = Calendar.current.startOfDay(for: Date())
        pedometerManager.fetchSteps(for: today) { [weak self] steps, error in
            guard let self = self, error == nil else {
                print("Error fetching steps: \(error!)")
                return
            }
            
            self.fetchOrCreateDailyLog(for: today) { dailyLog in
                DispatchQueue.main.async {
                    dailyLog.totalSteps = Int32(steps)
                    self.saveContext()
                }
            }
        }
    }

}

