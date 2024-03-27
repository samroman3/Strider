//
//  DetailView.swift
//  myPedometer
//
//  Created by Sam Roman on 1/24/24.
//

import SwiftUI
import SwiftUI

struct DetailView: View {
    @ObservedObject var viewModel: StatViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Date and Hourly Steps Chart
                dateAndChartSection
                
                //Chart key, steps, and Goal Status
                stepsAndGoalSection
                
                // Flights
                FlightsSection(ascending: viewModel.flightsAscended, descending: viewModel.flightsDescended)
                
                // Insights
                insightsSection
            }
        }
        .onAppear{
            viewModel.fetchData()
        }
        .alert(item: $viewModel.error) { error in
            Alert(title: Text("Error"), message: Text(error.localizedMessage), dismissButton: .default(Text("OK")))
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: Subviews
    
    private var dateAndChartSection: some View {
        VStack(alignment: .leading) {
            Text(viewModel.dateTitle)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.vertical)
            
            if #available(iOS 16.0, *) {
                HourlyStepsChart(hourlySteps: viewModel.hourlySteps, averageHourlySteps: viewModel.averageHourlySteps)
                    .frame(height: 200)
                    .padding(.horizontal, 20)
            } else {
                Text("Charts are not available on this version of iOS.")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
    }
    
    private var stepsAndGoalSection: some View {
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
            if viewModel.isToday && viewModel.goalAchievementStatus == .notAchieved {
                // Today and goal not achieved: blue progress bar
                CustomProgressView(totalSteps: Int(viewModel.dailySteps),
                                   dailyGoal: viewModel.dailyGoal,
                                   barColor: .blue).padding(.horizontal)
                
            } else {
                // Goal Status
                GoalStatusView(status: viewModel.goalAchievementStatus, type: .calorie)
                
            }
        }
    }
    
    private var insightsSection: some View {
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

