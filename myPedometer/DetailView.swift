//
//  DetailView.swift
//  myPedometer
//
//  Created by Sam Roman on 1/24/24.
//

import SwiftUI
import Charts

//struct DetailView: View {
//    @ObservedObject var viewModel: DetailViewModel
//    @ObservedObject var log: DailyLog
//
//    var body: some View {
//        ScrollView {
//            VStack(alignment: .leading, spacing: 20) {
//                // Header - Date and Total Steps
//                HStack {
//                    VStack(alignment: .leading, spacing: 4) {
//                        Text(viewModel.dateTitle)
//                            .font(.title2)
//                            .fontWeight(.bold)
//                        Text("\(log.totalSteps) steps")
//                            .font(.headline)
//                    }
//                    Spacer()
//                    VStack(alignment: .trailing, spacing: 4) {
//                        Text(viewModel.insightText)
//                            .font(.footnote)
//                            .foregroundColor(.orange)
//                        HStack(spacing: 4) {
//                            Text("\(log.totalSteps)")
//                                .font(.headline)
//                                .foregroundColor(.orange)
//                            Text("steps")
//                                .font(.footnote)
//                                .foregroundColor(.secondary)
//                        }
//                        HStack(spacing: 2) {
//                            Circle()
//                                .fill(Color.orange)
//                                .frame(width: 8, height: 8)
//                            Text("Today")
//                                .font(.footnote)
//                                .foregroundColor(.secondary)
//                            Circle()
//                                .fill(Color.gray)
//                                .frame(width: 8, height: 8)
//                            Text("Average")
//                                .font(.footnote)
//                                .foregroundColor(.secondary)
//                        }
//                    }
//                }
//                .padding(.horizontal)
//
//                // Chart for Hourly Step Data
//                if #available(iOS 16.0, *) {
//                    HourlyStepsChart(hourlySteps: viewModel.hourlySteps, averageHourlySteps: viewModel.averageHourlySteps)
//                        .frame(height: 200)
//                } else {
//                    Text("Charts are not available on this version of iOS.")
//                        .foregroundColor(.secondary)
//                }
//
//                // Flights Ascended and Descended
//                HStack {
//                    VStack {
//                        Image(systemName: "arrow.up")
//                            .foregroundColor(.blue)
//                        Text("\(log.flightsAscended)")
//                            .font(.headline)
//                        Text("Flights\nAscended")
//                            .font(.caption)
//                            .multilineTextAlignment(.center)
//                    }
//                    .frame(maxWidth: .infinity)
//
//                    VStack {
//                        Image(systemName: "arrow.down")
//                            .foregroundColor(.red)
//                        Text("\(log.flightsDescended)")
//                            .font(.headline)
//                        Text("Flights\nDescended")
//                            .font(.caption)
//                            .multilineTextAlignment(.center)
//                    }
//                    .frame(maxWidth: .infinity)
//                }
//                .padding()
//
//                // Goal Achievement and Highlights
//                VStack(alignment: .leading, spacing: 10) {
//                    if viewModel.isToday && !viewModel.isGoalAchieved {
//                        ProgressView(value: Double(log.totalSteps), total: Double(viewModel.dailyGoal))
//                            .progressViewStyle(LinearProgressViewStyle(tint: .orange))
//                    } else {
//                        GoalStatusView(steps: Int(log.totalSteps), goal: viewModel.dailyGoal)
//                    }
//
//                    Text("Highlights")
//                        .font(.headline)
//                    Text(viewModel.highlightText)
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                }
//                .padding(.horizontal)
//            }
//        }
//        .navigationTitle("Steps")
//        .navigationBarTitleDisplayMode(.inline)
//    }
//}
//
//
//struct HourlyStepsChart: View {
//    let hourlySteps: [HourlySteps]
//    let averageHourlySteps: [HourlySteps]
//
//    var body: some View {
//        if #available(iOS 16.0, *) {
//            Chart {
//                ForEach(hourlySteps, id: \.hour) { step in
//                    BarMark(
//                        x: .value("Hour", step.hour),
//                        y: .value("Today", step.steps)
//                    )
//                    .foregroundStyle(.orange)
//                }
//                ForEach(averageHourlySteps, id: \.hour) { step in
//                    BarMark(
//                        x: .value("Hour", step.hour),
//                        y: .value("Average", step.steps)
//                    )
//                    .foregroundStyle(.gray)
//                }
//            }
//            .chartXAxisLabel("Hour")
//        }
//    }
//}

struct DetailView: View {
    @ObservedObject var viewModel: DetailViewModel
    @ObservedObject var log: DailyLog
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header - Date, Total Steps, and Goal Achievement
                        HStack {
                            Text(viewModel.dateTitle)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Spacer()
                                if viewModel.isToday && !viewModel.isGoalAchieved {
                                    ProgressView(value: Double(log.totalSteps), total: Double(viewModel.dailyGoal))
                                        .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                                } else {
                                    GoalStatusView(steps: Int(log.totalSteps), goal: viewModel.dailyGoal)
                                }
                    }                .padding(.horizontal)
                Text("\(viewModel.dailySteps) steps")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                HStack(spacing: 2) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                    Text("Today")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 8, height: 8)
                    Text("Average")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                
                // Chart for Hourly Step Data
                if #available(iOS 16.0, *) {
                    HourlyStepsChart(hourlySteps: viewModel.hourlySteps, averageHourlySteps: viewModel.averageHourlySteps)
                        .frame(height: 200)
                        .padding(.horizontal, 20) // Added padding
                } else {
                    Text("Charts are not available on this version of iOS.")
                        .foregroundColor(.secondary)
                }
                
                Text("Daily average: \(viewModel.weeklyAvg)")
                    .font(.headline)
                    .fontWeight(.light)
                    .foregroundColor(.gray)
                
                // Flights Ascended and Descended
                HStack {
                    VStack {
                        Image(systemName: "arrow.up")
                            .foregroundColor(.blue)
                        Text("\(log.flightsAscended)")
                            .font(.headline)
                        Text("Flights\nAscended")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack {
                        Image(systemName: "arrow.down")
                            .foregroundColor(.red)
                        Text("\(log.flightsDescended)")
                            .font(.headline)
                        Text("Flights\nDescended")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
                // Insights Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Insights")
                        .font(.headline)
                    Text(viewModel.insightText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    // Additional insights can be added here
                }
                .padding(.horizontal)
                // Goal Achievement and Highlights
                VStack(alignment: .leading, spacing: 10) {
                    Text("Highlights")
                        .font(.headline)
                    Text(viewModel.highlightText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Steps")
        .navigationBarTitleDisplayMode(.inline)
    }
}

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

// Note: Implement GoalStatusView, HourlySteps, DailyLog, and other custom views or models as needed
