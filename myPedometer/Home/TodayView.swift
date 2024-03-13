//
//  TodayView.swift
//  myPedometer
//
//  Created by Sam Roman on 3/11/24.
//

import SwiftUI
struct TodayView: View {
    
    @EnvironmentObject private var viewModel: StepDataViewModel
    
    @State var dailyGoalViewIsPresented: Bool = false
    
    
    var body: some View {
        VStack{
            Spacer()
            HStack {
                Text("Today \(Date(), formatter: itemFormatter)")
                    .font(.title2)
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    dailyGoalViewIsPresented.toggle()
                }) {
                    Image(systemName: "gear")
                        .foregroundColor(.white)
                }
            }
            .padding([.horizontal, .top])
            .background(Color.black)
            TabView {
                // First page
                stepContent()
                    .background(Color.black.edgesIgnoringSafeArea(.all))
                    .tag(0)
                calorieContent()
                    .background(Color.black.edgesIgnoringSafeArea(.all))
                    .tag(1)
            }
            .tabViewStyle(PageTabViewStyle())
            Spacer()
        }.sheet(isPresented: $dailyGoalViewIsPresented) {
            DailyGoalView(dailyStepGoal: $viewModel.dailyStepGoal, dailyCalGoal: $viewModel.dailyCalGoal)
                .presentationBackground(Material.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .frame(width: 300, height: 400)
                .padding(.horizontal, 15)
        }
        
    }
    
    
    @ViewBuilder
    private func stepContent() -> some View {
        ZStack {
            BarGoalView(layers: 10, alignLeft: false)
            VStack {
                Spacer()
                VStack(alignment: .leading) {
                    HStack {
                        VStack {
                            Spacer()
                            AppTheme.greenGradient
                                .mask(
                                    Image(systemName: "shoe.circle")
                                        .imageScale(.large)
                                        .font(.system(size: 50))
                                )
                                .frame(width: 70, height: 70)
                            Text("\(viewModel.todayLog?.totalSteps ?? 0)")
                                .font(.headline)
                                .foregroundColor(.white)
                            if let totalSteps = viewModel.todayLog?.totalSteps, totalSteps < viewModel.dailyStepGoal {
                                Text("\(viewModel.dailyStepGoal - Int(totalSteps)) remaining")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                            } else {
                                Text("Goal complete!")
                                    .font(.headline)
                                    .foregroundColor(.green)
                            }
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func calorieContent() -> some View {
        ZStack {
            BarGoalView(layers: 10, alignLeft: true)
            VStack {
                Spacer()
                VStack(alignment: .trailing) {
                    HStack {
                        Spacer()
                        VStack {
                            Spacer()
                            AppTheme.redGradient
                                .mask(
                                    Image(systemName: "flame.circle")
                                        .imageScale(.large)
                                        .font(.system(size: 50))
                                )
                                .frame(width: 70, height: 70)
                            Text("\(Int(viewModel.caloriesBurned))")
                                .font(.headline)
                                .foregroundColor(.white)
                            if Int(viewModel.caloriesBurned) < viewModel.dailyCalGoal {
                                Text("\(viewModel.dailyCalGoal - Int(viewModel.caloriesBurned)) remaining")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                            } else {
                                Text("Goal complete!")
                                    .font(.headline)
                                    .foregroundColor(.red)
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    private var itemFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d"
        return formatter
    }
    
}
