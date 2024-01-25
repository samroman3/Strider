//
//  DayCardView.swift
//  myPedometer
//
//  Created by Sam Roman on 1/24/24.
//

import SwiftUI

struct DayCardView: View {
    var log: DailyLog
    var liveStepCount: Int?
    let calendar = Calendar.current
    
    @State private var showMotion: Bool = false
    let animationDuration = 0.5

    // Retrieve the goal from UserDefaults, with a default value
    let dailyStepGoal = UserDefaults.standard.integer(forKey: "dailyStepGoal") == 0 ? 1000 : UserDefaults.standard.integer(forKey: "dailyStepGoal")

    var body: some View {
        VStack {
            Spacer()
            if isToday(log.date) {
                HStack {
                    Text("Today")
                        .font(.title3)
                        .bold()
                    Text("\(log.date ?? Date(), formatter: itemFormatter)")
                        .font(.subheadline)
                        .opacity(0.7)
                }
                HStack {
                    VStack{
                        Image(systemName: showMotion ? "figure.walk.motion" : "figure.walk")
                            .font(.system(size: 60))
                            .animation(.easeInOut(duration: animationDuration))
                            .onAppear { self.showMotion.toggle() }
                        Text("\(liveStepCount ?? 0) steps")
                            .font(.title)
                            .fontWeight(.semibold)
                    }
                    if (liveStepCount ?? 0) >= dailyStepGoal {
                        VStack{
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 40))
                                .foregroundColor(.green )
                            Text("Goal Reached")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                    }
                    ProgressCircleView(percentage: Double(liveStepCount ?? 0) / Double(dailyStepGoal))
                }
            } else {
                HStack {
                    VStack{
                        Text("\(Int(log.totalSteps)) steps")
                            .font(.title)
                            .fontWeight(.semibold)
                        Text("\(log.date ?? Date(), formatter: itemFormatter)")
                            .font(.subheadline)
                            .opacity(0.7)
                    }
                    GoalStatusView(steps: Int(log.totalSteps), goal: dailyStepGoal)
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: 400)
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.3), radius: 10, x: 0, y: 10)
        .padding(.vertical)
    }
    
    func isToday(_ date: Date?) -> Bool {
        return calendar.isDateInToday(date ?? Date())
    }
}

struct GoalStatusView: View {
    var steps: Int
    var goal: Int

    var body: some View {
        VStack {
            Image(systemName: steps >= goal ? "checkmark.circle" : "xmark.circle")
                .font(.system(size: 20))
                .foregroundColor(steps >= goal ? .green : .red)
            Text(steps >= goal ? "Goal Reached" : "Goal Not Reached")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(steps >= goal ? .green : .red)
        }
    }
}

//#Preview {
//    DayCardView()
//}
