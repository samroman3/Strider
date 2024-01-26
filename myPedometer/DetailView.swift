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
                // Header - Date and Total Steps
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.dateTitle)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("\(viewModel.dailySteps) steps")
                            .font(.headline)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(viewModel.insightText)
                            .font(.footnote)
                            .foregroundColor(.orange)
                        HStack(spacing: 4) {
                            Text("\(viewModel.dailySteps)")
                                .font(.headline)
                                .foregroundColor(.orange)
                            Text("steps")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
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
                    }
                }
                .padding(.horizontal)
                
                // Chart for Hourly Step Data
                if #available(iOS 16.0, *) {
                    HourlyStepsChart(hourlySteps: viewModel.hourlySteps)
                        .frame(height: 200)
                } else {
                    Text("Charts are not available on this version of iOS.")
                        .foregroundColor(.secondary)
                }
                
                // Flights Ascended and Descended
                HStack {
                    VStack {
                        Image(systemName: "arrow.up")
                            .foregroundColor(.blue)
                        Text("\(viewModel.flightsAscended)")
                            .font(.headline)
                        Text("Flights\nAscended")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack {
                        Image(systemName: "arrow.down")
                            .foregroundColor(.red)
                        Text("\(viewModel.flightsDescended)")
                            .font(.headline)
                        Text("Flights\nDescended")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
                
                // Goal Achievement and Highlights
                VStack(alignment: .leading, spacing: 10) {
                    if viewModel.isToday && !viewModel.isGoalAchieved {
                        ProgressView(value: Double(viewModel.dailySteps), total: Double(viewModel.dailyGoal))
                            .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                    } else {
                        GoalStatusView(steps: viewModel.dailySteps, goal: viewModel.dailyGoal)
                    }
                    
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
    
    var body: some View {
        if #available(iOS 16.0, *) {
            Chart(hourlySteps) { step in
                BarMark(
                    x: .value("Hour", step.hour),
                    y: .value("Steps", step.steps)
                )
                .foregroundStyle(step.steps > 0 ? .orange : .gray)
            }
            .chartXAxisLabel("Hour")
        }
    }
}

