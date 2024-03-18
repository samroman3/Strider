//
//  TodayView.swift
//  myPedometer
//
//  Created by Sam Roman on 3/11/24.
//

import SwiftUI
struct TodayView: View {
    
    @EnvironmentObject private var viewModel: StepDataViewModel
    @EnvironmentObject private var userSettingsManager: UserSettingsManager
    
    @State var profileViewIsPresented: Bool = false
    
    
    var body: some View {
            VStack {
                HStack {
                    Text("\(Date(), formatter: itemFormatter)")
                        .font(.title2)
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: {
                        profileViewIsPresented.toggle()
                    }) {
                        NavigationLink(destination: ProfileSetupView().environmentObject(userSettingsManager), isActive: $profileViewIsPresented) {
                            Image(systemName: "gear")
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding([.horizontal])
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
