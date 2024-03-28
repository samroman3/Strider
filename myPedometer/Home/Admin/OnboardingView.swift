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
    @State private var consentDenied = false
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
                   } else {
                       // Show the consent view only if it needs to be shown and iCloud is available
                       ConsentView(consentGiven: $consentGiven, onConsentGiven: {
                           withAnimation(.spring()) {
                               consentGiven = true
                               onOnboardingComplete()
                           }
                       })
                       .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                   }
               } else {
                   // Show the iCloud required view if iCloud is not available
                   iCloudRequiredView()
               }
           }
           .onAppear {
               // Check iCloud availability here
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
            LinearGradient(gradient: Gradient(colors: [AppTheme.darkGray, AppTheme.darkerGray]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            
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
                // App Name
                Text("STRIDER")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(radius: 5)
                
                // Features Description
                VStack(spacing: 10) {
                    Text("Track steps.")
                        .multilineTextAlignment(.center)
                        .font(.title3)
                        .foregroundColor(.white)
                    
                    Text("Challenge friends.")
                        .multilineTextAlignment(.center)
                        .font(.title3)
                        .foregroundColor(.white)
                    Text("Reach your goals together.")
                        .multilineTextAlignment(.center)
                        .font(.title3)
                        .foregroundColor(.white)
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 20)
//                .background(Color.black.opacity(0.5))
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

                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                                .imageScale(.large)
                            Text("HealthKit Integration")
                                .font(.headline)
                                .foregroundStyle(.primary)
                        }
                        Text("With your consent, we access HealthKit to track relevant health data such as activity levels, calories burned and steps taken. This data and all calculations remain on your device to maintain your privacy.")
                            .foregroundStyle(.primary)
                    }
                    .padding()

                    ConsentAgreementText()

                    Button("Accept", action: onConsentGiven)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding()
                        .background(Material.ultraThin)
                        .cornerRadius(10)
                    Button("Deny", action: onConsentGiven)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding()
                        .background(Material.ultraThin)
                        .cornerRadius(10)
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
            By continuing, you acknowledge and agree to the use of iCloud for storage and HealthKit for health data integration as outlined above. Your privacy is our top priority, and you have full control over your data.
            """)
            .font(.callout)
            .foregroundStyle(.primary)
            .padding()
    }
}

struct iCloudRequiredView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "icloud.and.arrow.up") // An iCloud-related symbol
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

//
//struct OnboardingView_Previews: PreviewProvider {
//    static var previews: some View {
//        OnboardingView(onOnboardingComplete: {})
//    }
//}

struct WelcomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeScreen(onGetStarted: {})
            .previewLayout(.sizeThatFits)
    }
}

