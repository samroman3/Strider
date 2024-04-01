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
    @Environment(\.colorScheme) var colorScheme

    @State var profileViewIsPresented: Bool = false
    
    @State private var isSpinning = false
    
    
    var body: some View {
        VStack {
            HStack(alignment: .firstTextBaseline){
                Text("\(Date(), formatter: itemFormatter)")
                    .font(.title2)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                Spacer()
            }
            .padding([.horizontal])
            .foregroundColor(colorScheme == .dark ? .black : .white)
            TabView {
                // First page
                stepContent()
                    .background(colorScheme == .dark ? .black : .white).edgesIgnoringSafeArea(.all)
                    .tag(0)
                    .onAppear(){
                        spinIcon()
                    }
                calorieContent()
                    .background(colorScheme == .dark ? .black : .white).edgesIgnoringSafeArea(.all)
                    .tag(1)
                    .onAppear(){
                        spinIcon()
                    }
            }
            .tabViewStyle(PageTabViewStyle())
            Spacer()
        }
        .navigationBarItems(trailing:
                                Button(action: {
            HapticFeedbackProvider.impact()
            profileViewIsPresented.toggle()
        }) {
            Image(systemName: "gear")
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .font(.title2)
        })
        .sheet(isPresented: $profileViewIsPresented, content: {
            ProfileSetupView().environmentObject(userSettingsManager)
        })
    }
    
    
    
    @ViewBuilder
    private func stepContent() -> some View {
        ZStack {
            BarGoalView(alignLeft: false, layers: 10)
            VStack {
                Spacer()
                VStack(alignment: .leading) {
                    HStack {
                        VStack {
                            Spacer()
                            Button(action: {
                                // Trigger the refresh data action in your viewModel
                                viewModel.refreshData()
                                
                              spinIcon()
                            }) {
                                AppTheme.greenGradient
                                    .mask(
                                        Image(systemName: "shoe.circle")
                                            .imageScale(.large)
                                            .font(.system(size: 50))
                                    )
                                    .rotation3DEffect(.degrees(isSpinning ? 360 : 0), axis: (x: 0, y: 1, z: 0))
                                    .frame(width: 70, height: 70)
                            }
                            Text("\(viewModel.animatedStepCount)")
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .white : .gray)
                            Text("steps")
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .white : .gray)
                            if viewModel.animatedStepCount < viewModel.dailyStepGoal {
                                Text("\(viewModel.dailyStepGoal - Int(viewModel.animatedStepCount)) remaining")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                            } else {
                                Text("Goal complete!")
                                    .font(.headline)
                                    .foregroundColor(.green)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        Spacer()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func calorieContent() -> some View {
        ZStack {
            BarGoalView(alignLeft: true, layers: 10)
            VStack {
                Spacer()
                VStack(alignment: .trailing) {
                    HStack {
                        Spacer()
                        VStack {
                            Spacer()
                            Button(action: {
                                // Trigger the refresh data action in your viewModel
                                viewModel.refreshData()
                                spinIcon()
                            }) {
                                AppTheme.redGradient
                                    .mask(
                                        Image(systemName: "flame.circle")
                                            .imageScale(.large)
                                            .font(.system(size: 50))
                                    )
                                    .rotation3DEffect(.degrees(isSpinning ? 360 : 0), axis: (x: 0, y: 1, z: 0))
                                    .frame(width: 70, height: 70)
                            }
                                .frame(width: 70, height: 70)
                            Text("\(Int(viewModel.caloriesBurned))")
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .white : .gray)
                            Text("calories")
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .white : .gray)
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
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
    
    private func spinIcon() {
        HapticFeedbackProvider.impact()
        withAnimation(.linear(duration: 1)) {
            isSpinning.toggle()
        }
        // Reset the spin after the duration to allow for re-spin
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isSpinning.toggle()
        }
    }
    
    private var itemFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d"
        return formatter
    }
    
}
