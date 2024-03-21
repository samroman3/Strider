//
//  ContentView.swift
//  myPedometer
//
//  Created by Sam Roman on 1/24/24.
//
import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appState: AppState
    var userSettingsManager = UserSettingsManager.shared
    var cloudKitManager = CloudKitManager.shared
    @StateObject var stepDataViewModel: StepDataViewModel
    @StateObject var challengeViewModel: ChallengeViewModel

    @State private var showSignInView = false

    init(pedometerDataProvider: PedometerDataProvider & PedometerDataObservable, context: NSManagedObjectContext) {
        _stepDataViewModel = StateObject(wrappedValue: StepDataViewModel(pedometerDataProvider: pedometerDataProvider, userSettingsManager: UserSettingsManager.shared))
        _challengeViewModel = StateObject(wrappedValue: ChallengeViewModel())
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
        .environmentObject(stepDataViewModel)
        .environmentObject(userSettingsManager)
        .environmentObject(challengeViewModel)
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
                            challengeViewModel.acceptChallenge(challengeDetails)
                            appState.currentChallengeState = nil
                        }, onDecline: {
                            challengeViewModel.declineChallenge(challengeDetails)
                            appState.currentChallengeState = nil
                        })
                    case .challengeActive(let challengeDetails):
                        // Implement your view for an active challenge
                        Text("Challenge is now active with details: \(challengeDetails.goalSteps)")
                    case .challengeCompleted(let challengeDetails):
                        // Implement your view for a completed challenge
                        Text("Challenge completed! Goal steps: \(challengeDetails.goalSteps)")
                    }
                }
    }
}

