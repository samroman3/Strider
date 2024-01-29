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
                }
                }.padding(.horizontal)
            VStack(alignment: .center, spacing: 10) {
                //Chart Key
                HStack(spacing: 2) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                    Text(viewModel.isToday ? "Today" : "This Day")
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
                if viewModel.isToday {
                    if !viewModel.isGoalAchieved {
                        // Today and goal not achieved: blue progress bar
                        CustomProgressView(totalSteps: Int(viewModel.dailySteps),
                                           dailyGoal: viewModel.dailyGoal,
                                           barColor: .blue).padding(.horizontal)
                    } else {
                        // Today and goal achieved:
                        GoalStatusView(steps: Int(viewModel.dailySteps), goal: viewModel.dailyGoal)
                    }
                } else {
                    // Not today:
                    GoalStatusView(steps: Int(viewModel.dailySteps), goal: viewModel.dailyGoal)
                    
                }
                // Flights Ascended and Descended
                FlightsSection(ascending: viewModel.flightsAscended, descending: viewModel.flightsDescended)
            }
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
    var ascending: Int = 0
    var descending: Int = 0
    
    var body: some View {
        HStack {
            FlightInfoView(type: "Ascended", count: ascending, iconColor: .blue)
            FlightInfoView(type: "Descended", count: descending, iconColor: .red)
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
            .chartXAxis {
                AxisMarks(values: .stride(by: 1)) { value in
                    if let hour = value.as(Int.self) {
                        AxisTick()
                        switch hour {
                        case 0, 24:
                            AxisValueLabel("12AM")
                        case 12:
                            AxisValueLabel("12PM")
                        default:
                            AxisValueLabel("")
                        }
                    }
                }
            }
        }
    }
}
