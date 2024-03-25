//
//  MainChallengeView.swift
//  myPedometer
//
//  Created by Sam Roman on 3/13/24.
//

import SwiftUI

struct MainChallengeView: View {
    @EnvironmentObject var challengeViewModel: ChallengeViewModel
    
    @State private var isCreateViewPresented = false
    
    var body: some View {
        ScrollView {
            VStack {
                Spacer()
                if !challengeViewModel.pendingChallenges.isEmpty {
                    PendingChallengesView()
                        .environmentObject(challengeViewModel)
                }
                ActiveChallengesView()
                    .environmentObject(challengeViewModel)
                    .padding(.vertical)
                PastChallengesView()
                    .padding(.vertical)
                Spacer()
            }
        }
        .navigationBarItems(trailing: Button(action: {
            isCreateViewPresented = true
        }) {
            NavigationLink(destination: 
                            CreateChallengeView()
                .environmentObject(challengeViewModel)
                           , isActive: $isCreateViewPresented) {}
            Image(systemName: "plus.circle")
                .font(.title2)
                .foregroundStyle(.white)
        })
        .background(.black)
    }
}
