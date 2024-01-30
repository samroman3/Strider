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
    func fetchOrCreateDailyLog(for date: Date, completion: @escaping (DailyLog, Error?) -> Void) {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let request: NSFetchRequest<DailyLog> = DailyLog.fetchRequest()
        request.predicate = NSPredicate(format: "date == %@", startOfDay as NSDate)
        
        do {
            let results = try context.fetch(request)
            if let existingLog = results.first {
                completion(existingLog, nil)
            } else {
                let newLog = DailyLog(context: context)
                newLog.date = startOfDay
                completion(newLog, nil)
            }
        } catch {
            print("Error fetching DailyLog: \(error)")
            let newLog = DailyLog(context: context)
            newLog.date = startOfDay
            completion(newLog, error)
        }
    }

}
