//
//  CustomTabBarView.swift
//  myPedometer
//
//  Created by Sam Roman on 3/11/24.
//

import SwiftUI

struct CustomTabBarView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var userSettingsManager: UserSettingsManager
    @EnvironmentObject private var stepViewModel: StepDataViewModel
    @EnvironmentObject private var challengeViewModel: ChallengeViewModel
    
    @State private var selectedTab: Tab = .today

    var body: some View {
        VStack {
            switch selectedTab {
            case .today:
                NavigationView{
                    TodayView()
                        .environmentObject(userSettingsManager)
                        .navigationTitle("Today")
                }
            case .awards:
                NavigationView{
                    AwardsView()
                        .navigationTitle("Awards")
                }
            case .challenge:
                NavigationView{
                    MainChallengeView()
                        .navigationTitle("Challenge")
                }
            }
            // Custom Tab Bar
            HStack(spacing: 50) {
                TabBarButton(icon: "shoe", selectedIcon: "shoe.fill", tab: .today, selectedTab: $selectedTab, color: .blue)
                TabBarButton(icon: "trophy", selectedIcon: "trophy.fill", tab: .awards, selectedTab: $selectedTab, color: .yellow)
//                TabBarButton(icon: "chart.bar", selectedIcon: "chart.bar.fill", tab: .week, selectedTab: $selectedTab, color: .blue)
                TabBarButton(icon: "flag.2.crossed", selectedIcon: "flag.2.crossed.fill", tab: .challenge, selectedTab: $selectedTab, color: .purple)
                
            }
            .padding([.horizontal, .vertical])
        }
        .onAppear(){
            userSettingsManager.loadUserSettings()
            challengeViewModel.loadActiveChallenges()
        }
        .background(.black)
    }

    enum Tab {
        case today, awards, challenge
    }
}

struct TabBarButton: View {
    let icon: String
    let selectedIcon: String
    let tab: CustomTabBarView.Tab
    @Binding var selectedTab: CustomTabBarView.Tab
    let color: Color
    

    var body: some View {
        Image(systemName: selectedTab == tab ? selectedIcon : icon)
            .foregroundColor(color)
            .imageScale(.medium)
            .font(.system(size: 25))
            .onTapGesture {
                withAnimation(.snappy) {
                    selectedTab = tab
                }
            }
    }
}

#Preview {
    CustomTabBarView()
}
