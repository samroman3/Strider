//
//  ContentView.swift
//  myPedometer
//
//  Created by Sam Roman on 1/24/24.
//
import SwiftUI
import CoreData

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var userSettingsManager: UserSettingsManager
    @EnvironmentObject var cloudKitManager: CloudKitManager
    var pedometerDataProvider: PedometerDataProvider & PedometerDataObservable
    
    init(pedometerDataProvider: PedometerDataProvider & PedometerDataObservable) {
        self.pedometerDataProvider = pedometerDataProvider
    }

    var body: some View {
        Group {
            // Determine the view based on the onboarding status
            if !userSettingsManager.hasCompletedOnboarding {
                OnboardingView(onOnboardingComplete: handleOnboardingComplete)
                    .environmentObject(userSettingsManager)
            } else {
                mainContentView()
                    .environmentObject(StepDataViewModel(pedometerDataProvider: pedometerDataProvider, userSettingsManager: userSettingsManager))
                    .environmentObject(ChallengeViewModel(userSettingsManager: userSettingsManager, cloudKitManager: cloudKitManager))
                    .environmentObject(userSettingsManager)
                
            }
        }
    }

    private func handleOnboardingComplete() {
        userSettingsManager.checkiCloudAvailability { available in
            userSettingsManager.hasCompletedOnboarding = true
        }
    }

    @ViewBuilder
    private func mainContentView() -> some View {
        ZStack {
            CustomTabBarView()
                       if let alertItem = appState.alertItem {
                           CustomModalView(alertItem: alertItem) {
                               appState.alertItem = nil
                           }.presentationBackground(.thinMaterial)
                       }
        }
        .fullScreenCover(item: $appState.currentChallengeState) { challengeState in
                switch challengeState {
                case .invitation(let challengeDetails):
                    SharedChallengeDetailView(challengeDetails: challengeDetails, onAccept: {
                        Task {
                            await appState.acceptChallenge()
                        }
                    }, onDecline: {
                        appState.declineChallenge()
                    }).environmentObject(userSettingsManager)
                        .presentationBackground(.thinMaterial)
                case .challengeActive(_):
                    EmptyView()
                case .challengeCompleted(_):
                    EmptyView()
                }
            }
    }
}

