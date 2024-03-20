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
    @EnvironmentObject var userSettingsManager: UserSettingsManager
    @EnvironmentObject var cloudKitManager: CloudKitManager
    @StateObject var stepDataViewModel: StepDataViewModel
    @StateObject var challengeViewModel: ChallengeViewModel

    @State private var showSignInView = false

    init(pedometerDataProvider: PedometerDataProvider & PedometerDataObservable, context: NSManagedObjectContext) {
        _stepDataViewModel = StateObject(wrappedValue: StepDataViewModel(pedometerDataProvider: pedometerDataProvider, userSettingsManager: UserSettingsManager.shared))
        _challengeViewModel = StateObject(wrappedValue: ChallengeViewModel(userSettingsManager: UserSettingsManager.shared, cloudKitManager: CloudKitManager.shared))
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
            .sheet(isPresented: $appState.isHandlingShare) {
                if let challengeDetails = appState.sharedChallengeDetails {
                    SharedChallengeDetailView(challengeDetails: challengeDetails, onAccept: {
                        challengeViewModel.acceptChallenge(challengeDetails)
                        appState.isHandlingShare = false // Dismiss the sheet
                        }, onDecline: {
                        challengeViewModel.declineChallenge(challengeDetails)
                        appState.isHandlingShare = false
                       })
                }
            }
    }
}

