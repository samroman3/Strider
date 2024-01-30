//
//  PedometerDataProcessor.swift
//  myPedometer
//
//  Created by Sam Roman on 1/30/24.
//

import Foundation

class PedometerDataProcessor {
    
    static func calculateMostAndLeastActiveHours(hourlySteps: [HourlySteps]) -> (mostActive: Int, leastActive: Int) {
        guard !hourlySteps.isEmpty else { return (0, 0) }
        
        let sortedBySteps = hourlySteps.sorted { $0.steps > $1.steps }
        let mostActiveHour = sortedBySteps.first?.hour ?? 0
        let leastActiveHour = sortedBySteps.last?.hour ?? 0
        return (mostActiveHour, leastActiveHour)
    }
    
    static func calculateMostActivePeriodOfDay(hourlySteps: [HourlySteps]) -> String {
        // morning: 5 AM - 12 PM, afternoon: 12 PM - 5 PM, evening: 5 PM - 9 PM
        let morningSteps = hourlySteps.filter { 5...11 ~= $0.hour }.reduce(0) { $0 + $1.steps }
        let afternoonSteps = hourlySteps.filter { 12...16 ~= $0.hour }.reduce(0) { $0 + $1.steps }
        let eveningSteps = hourlySteps.filter { 17...20 ~= $0.hour }.reduce(0) { $0 + $1.steps }
        
        let maxSteps = max(morningSteps, afternoonSteps, eveningSteps)
        switch maxSteps {
        case morningSteps:
            return "Morning"
        case afternoonSteps:
            return "Afternoon"
        default:
            return "Evening"
        }
    }
    
    static func compareTodayWithWeeklyAverage(todayTotalSteps: Int, weeklyAvg: Int) -> String {
        return todayTotalSteps > weeklyAvg ? "more active" : "less active"
    }
    
}
