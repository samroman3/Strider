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

    @State private var showSignInView = false

    init(pedometerDataProvider: PedometerDataProvider & PedometerDataObservable) {
        self.pedometerDataProvider = pedometerDataProvider
    }

    var body: some View {
        Group {
            // Determine the view based on the onboarding and sign-in status
            if !userSettingsManager.hasCompletedOnboarding {
                OnboardingView(onOnboardingComplete: handleOnboardingComplete)
                    .environmentObject(userSettingsManager)
            } else if showSignInView {
                SignInView(isPresented: $showSignInView, onSignInComplete: handleSignInComplete)
                    .environmentObject(userSettingsManager)
            } else {
                mainContentView()
            }
        }
        .environmentObject(StepDataViewModel(pedometerDataProvider: pedometerDataProvider, userSettingsManager: userSettingsManager))
        .environmentObject(ChallengeViewModel(userSettingsManager: userSettingsManager, cloudKitManager: cloudKitManager))
        .environmentObject(userSettingsManager)

    }

    private func handleOnboardingComplete() {
        userSettingsManager.checkiCloudAvailability { available in
            userSettingsManager.hasCompletedOnboarding = true
            if available && !userSettingsManager.hasSignedIn {
                showSignInView = true
            }
        }
    }

    private func handleSignInComplete() {
        userSettingsManager.hasSignedIn = true
    }

    @ViewBuilder
    private func mainContentView() -> some View {
        CustomTabBarView()
                .sheet(item: $appState.currentChallengeState) { challengeState in
                    switch challengeState {
                    case .invitation(let challengeDetails):
                        SharedChallengeDetailView(challengeDetails: challengeDetails, onAccept: {
                            Task {
                                    await appState.acceptChallenge()
                                    }
                        }, onDecline: {
                            appState.declineChallenge()
                        })
                    case .challengeActive(let challengeDetails):
                        Text("Challenge is now active! Goal: \(challengeDetails.goalSteps), End Time: \(challengeDetails.endTime.formatted())")
                    case .challengeCompleted(let challengeDetails):
                        Text("Challenge completed! Goal steps: \(challengeDetails.goalSteps), winner: \(challengeDetails.winner ?? "")")
                    }
                }
    }
}

