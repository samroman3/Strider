//
//  AppState.swift
//  myPedometer
//
//  Created by Sam Roman on 3/14/24.
//

import Foundation

class AppState: ObservableObject {
    static let shared = AppState()

    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }
    
    @Published var iCloudConsentGiven: Bool {
        didSet {
            UserDefaults.standard.set(iCloudConsentGiven, forKey: "iCloudConsentGiven")
        }
    }

    // Add a published property for hasSignedIn
    @Published var hasSignedIn: Bool {
        didSet {
            UserDefaults.standard.set(hasSignedIn, forKey: "hasSignedIn")
        }
    }

    init() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        iCloudConsentGiven = UserDefaults.standard.bool(forKey: "iCloudConsentGiven")
        // Initialize hasSignedIn from UserDefaults
        hasSignedIn = UserDefaults.standard.bool(forKey: "hasSignedIn")
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    func giveiCloudConsent() {
        iCloudConsentGiven = true
    }
    
    // Add a method to mark sign-in as completed
    func signInCompleted() {
        hasSignedIn = true
    }
}
