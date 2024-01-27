//
//  DetailView.swift
//  myPedometer
//
//  Created by Sam Roman on 1/24/24.
//

import SwiftUI
import Charts

struct DetailView: View {
    @ObservedObject var viewModel: DetailViewModel
    @ObservedObject var log: DailyLog
    var isToday: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Date Header
                VStack(alignment: .leading) {
                    HStack {
                        Text(viewModel.dateTitle)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }.padding(.vertical)
                    
                    // Chart for Hourly Step Data
                    if #available(iOS 16.0, *) {
                        HourlyStepsChart(hourlySteps: viewModel.hourlySteps, averageHourlySteps: viewModel.averageHourlySteps)
                            .frame(height: 200)
                            .padding(.horizontal, 20) // Added padding
                    } else {
                        Text("Charts are not available on this version of iOS.")
                            .foregroundColor(.secondary)
                    }
                }.padding(.horizontal)
                //Chart Key
                HStack(spacing: 2) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                    Text(isToday ? "Today" : "This Day")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 8, height: 8)
                    Text("Average")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }.padding(.horizontal)
                    Text("\(viewModel.dailySteps) steps")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                        .padding(.leading)
                VStack(alignment: .center) {
                    if isToday {
                        if !viewModel.isGoalAchieved {
                            // Today and goal not achieved: blue progress bar
                            CustomProgressView(totalSteps: Int(log.totalSteps),
                                               dailyGoal: viewModel.dailyGoal,
                                               barColor: .blue)
                        } else {
                            // Today and goal achieved: show goal status and green progress bar
                            GoalStatusView(steps: Int(log.totalSteps), goal: viewModel.dailyGoal)
//                            CustomProgressView(totalSteps: Int(log.totalSteps),
//                                               dailyGoal: viewModel.dailyGoal,
//                                               barColor: .green)
                        }
                    } else {
                        // Not today: show goal status and progress bar in green or red
                        GoalStatusView(steps: Int(log.totalSteps), goal: viewModel.dailyGoal)
//                        CustomProgressView(totalSteps: Int(log.totalSteps),
//                                           dailyGoal: viewModel.dailyGoal,
//                                           barColor: viewModel.isGoalAchieved ? .green : .red)
                    }
                    
                }.padding(.horizontal)
                // Flights Ascended and Descended
                FlightsSection(log: log)
                
                // Insights Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Insights")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(viewModel.insights, id: \.self) { insight in
                        Text(insight)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                }
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

//MARK: CustomProgressView
struct CustomProgressView: View {
    var totalSteps: Int
    var dailyGoal: Int
    var barColor: Color
    
    var body: some View {
        ProgressView(value: Double(min(totalSteps, dailyGoal)), total: Double(dailyGoal))
            .progressViewStyle(LinearProgressViewStyle(tint: barColor))
        Text("Goal: \(dailyGoal) steps")
            .foregroundColor(barColor)
    }
}
//MARK: FlightSection
struct FlightsSection: View {
    var log: DailyLog
    
    var body: some View {
        HStack {
            FlightInfoView(type: "Ascended", count: Int(log.flightsAscended), iconColor: .blue)
            FlightInfoView(type: "Descended", count: Int(log.flightsDescended), iconColor: .red)
        }
        .padding()
    }
}

struct FlightInfoView: View {
    var type: String
    var count: Int
    var iconColor: Color
    
    var body: some View {
        VStack {
            Image(systemName: "arrow.\(type == "Ascended" ? "up" : "down")")
                .foregroundColor(iconColor)
            Text("\(count)")
                .font(.headline)
            Text("Flights\n\(type)")
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}
//MARK: HourlyStepsChart
struct HourlyStepsChart: View {
    let hourlySteps: [HourlySteps]
    let averageHourlySteps: [HourlySteps]
    
    var body: some View {
        if #available(iOS 16.0, *) {
            Chart {
                ForEach(hourlySteps, id: \.hour) { step in
                    BarMark(
                        x: .value("Hour", step.hour),
                        y: .value("Today", step.steps)
                    )
                    .foregroundStyle(.orange)
                }
                ForEach(averageHourlySteps, id: \.hour) { step in
                    BarMark(
                        x: .value("Hour", step.hour),
                        y: .value("Average", step.steps)
                    )
                    .foregroundStyle(.gray)
                }
            }
            .chartXAxisLabel("Hour")
        }
    }
}
