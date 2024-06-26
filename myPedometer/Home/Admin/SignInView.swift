//
//  SignInView.swift
//  myPedometer
//
//  Created by Sam Roman on 3/14/24.
//

import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject var userSettingsManager: UserSettingsManager
    @Environment(\.colorScheme) var colorScheme
    @Binding var isPresented: Bool
    @State private var animationAmount = 0.0
    
    var onSignInComplete: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            AppTheme.greenGradient
                          .mask(
                              Image(systemName: "shoe.circle")
                                  .resizable()
                                  .aspectRatio(contentMode: .fit)
                                  .frame(width: 300, height: 400)
                                  .shadow(radius: 10)
                                  .font(.largeTitle)
                                  .fontWeight(.bold)
                                  .foregroundStyle(.primary)
                                  .padding()
                                  .scaleEffect(1 + CGFloat(animationAmount))
                                  .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: animationAmount)
                                  .onAppear {
                                      animationAmount = 0.1
                                  }
                          )
            
            Spacer()
            
            SignInWithAppleButton(
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    switch result {
                    case .success(let authResults):
                        if let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential {
                             let userID = appleIDCredential.user // This is the stable, unique identifier
                             let fullName = "\(appleIDCredential.fullName?.givenName ?? "Fulltime")\(appleIDCredential.fullName?.familyName ?? "Strider")"
                             userSettingsManager.updateUserAfterSignInWithApple(userID: userID, fullName: fullName)
                             self.isPresented = false
                             onSignInComplete()
                         }
                    case .failure(let error):
                        print("Authorization failed: \(error)")
                    }
                }
            )
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .frame(width: 280, height: 45)
            .padding()
            .background(AppTheme.greenGradient.cornerRadius(22.5))
            .shadow(radius: 10)
            
            Spacer()
        }
        .background(LinearGradient(gradient: Gradient(colors: [colorScheme == .dark ? .black : .white, .gray]), startPoint: .top, endPoint: .bottom).edgesIgnoringSafeArea(.all))
    }
}
