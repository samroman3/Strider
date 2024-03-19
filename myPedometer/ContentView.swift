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
    @EnvironmentObject private var userSettingsManager: UserSettingsManager
    @StateObject private var stepDataViewModel: StepDataViewModel
    @StateObject private var challengeViewModel: ChallengeViewModel


    @State private var showSignInView = false

    init(pedometerDataProvider: PedometerDataProvider & PedometerDataObservable, context: NSManagedObjectContext) {
        let userSettingsManager = UserSettingsManager.shared
            _stepDataViewModel = StateObject(wrappedValue: StepDataViewModel(pedometerDataProvider: pedometerDataProvider, userSettingsManager: userSettingsManager))
        _challengeViewModel = StateObject(wrappedValue: ChallengeViewModel(userSettingsManager: userSettingsManager, challengeManager: ChallengeManager()))
    }

    var body: some View {
        Group {
            if !userSettingsManager.hasCompletedOnboarding {
                OnboardingView(onOnboardingComplete: {
                    userSettingsManager.checkiCloudAvailability { available in
                        userSettingsManager.hasCompletedOnboarding = true
                        if available && !userSettingsManager.hasSignedIn {
                            showSignInView = true
                        }
                    }
                }).environmentObject(userSettingsManager)
            } else if showSignInView {
                SignInView(isPresented: $showSignInView, onSignInComplete: {
                    userSettingsManager.hasSignedIn = true
                })
                .environmentObject(userSettingsManager)
            } else {
                CustomTabBarView()
                    .environmentObject(stepDataViewModel)
                    .environmentObject(userSettingsManager)
                    .environmentObject(challengeViewModel)
            }
        }
    }
}

