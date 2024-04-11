//
//  OnboardingView.swift
//  myPedometer
//
//  Created by Sam Roman on 3/14/24.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var userSettingsManager: UserSettingsManager
    @State private var showConsent = false
    @State private var consentGiven = false
    @State private var showGoalSetup = false // Controlled state for showing goal setup
    @State private var iCloudAvailable: Bool = false
    
    var onOnboardingComplete: () -> Void
    
    var body: some View {
        VStack {
            if iCloudAvailable {
                if !showConsent {
                    WelcomeScreen(onGetStarted: {
                        withAnimation(.spring()) {
                            showConsent = true
                        }
                    })
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                } else if !consentGiven {
                    ConsentView(consentGiven: $consentGiven, onConsentGiven: {
                        withAnimation(.spring()) {
                            consentGiven = true
                            showGoalSetup = true // Transition to goal setup after consent
                        }
                    })
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                }
                
                if showGoalSetup {
                    SetUpProfileView(onConfirm:{
                        withAnimation(.spring()) {
                            onOnboardingComplete() // Complete the onboarding after goals are set
                        }
                    }
                    )
                    .environmentObject(userSettingsManager)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                }
            } else {
                iCloudRequiredView()
            }
        }
        .onAppear {
            userSettingsManager.checkiCloudAvailability { available in
                iCloudAvailable = available
            }
        }
    }
}


struct WelcomeScreen: View {
    var onGetStarted: () -> Void
    
    var body: some View {
        ZStack {
            // Background gradient
            VStack(spacing: 20) {
                Spacer()
                //Icon
                AppTheme.greenGradient
                    .mask(
                        Image(systemName: "shoe.circle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 300, height: 400)
                            .shadow(radius: 10)
                    )
                // Features Description
                VStack(spacing: 10) {
                    Text("Track steps.")
                        .multilineTextAlignment(.center)
                        .font(.title3)
                    
                    Text("Challenge friends.")
                        .multilineTextAlignment(.center)
                        .font(.title3)
                    Text("Reach your goals together.")
                        .multilineTextAlignment(.center)
                        .font(.title3)
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 20)
                .cornerRadius(15)
                
                // Get Started Button
                Button(action: onGetStarted) {
                    HStack {
                        Text("Get Started")
                            .fontWeight(.medium)
                            .font(.title)
                            .foregroundColor(.white)
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(.white)
                    }.background(
                        // Apply the green gradient as the button background
                        AppTheme.greenGradient
                            .cornerRadius(20)
                            .frame(minWidth: 300)
                        
                    )
                    .padding()
                    .shadow(radius: 10)
                }
                .padding([.horizontal,.vertical])
                
                Spacer()
            }
        }
    }
}


struct ConsentView: View {
    @Binding var consentGiven: Bool
    var onConsentGiven: () -> Void
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Privacy & Data Use")
                        .font(.title)
                        .foregroundColor(.primary)
                        .padding()
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "icloud.fill")
                                .foregroundColor(.blue)
                                .imageScale(.large)
                            Text("iCloud Sync")
                                .font(.headline)
                                .foregroundStyle(.primary)
                        }
                        Text("Your data is securely stored in iCloud, ensuring it's private and accessible across all your devices. We use iCloud to keep data in sync and secure.")
                            .foregroundStyle(.primary)
                            .padding(.bottom)
                    }
                    .padding()
                    
                    ConsentAgreementText()
                    
                    Button("Continue", action: onConsentGiven)
                        .buttonStyle(AppButtonStyle(backgroundColor: AppTheme.greenGradient))
                        .font(.headline)
                        .padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cornerRadius(20)
    }
}

struct ConsentAgreementText: View {
    var body: some View {
        Text("""
            By continuing, you acknowledge and agree to the use of iCloud for storage and data integration as outlined above. Your privacy is our top priority, and you have full control over your data.
            """)
        .font(.callout)
        .foregroundStyle(.primary)
        .padding()
    }
}

struct iCloudRequiredView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "icloud.and.arrow.up")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            Text("iCloud Account Required")
                .font(.title)
                .fontWeight(.bold)
            
            Text("This app requires an iCloud account. Please sign in or create one in your device's Settings to continue. If you have denied access you may accept it again in the App settings and permissions.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
            
            Button(action: {
                // Attempt to open the Settings app
                if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("Open Settings")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

struct iCloudRequiredView_Previews: PreviewProvider {
    static var previews: some View {
        iCloudRequiredView()
    }
}



struct ConsentView_Previews: PreviewProvider {
    static var previews: some View {
        ConsentView(consentGiven: .constant(false), onConsentGiven: {})
    }
}

struct WelcomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeScreen(onGetStarted: {})
            .previewLayout(.sizeThatFits)
    }
}

