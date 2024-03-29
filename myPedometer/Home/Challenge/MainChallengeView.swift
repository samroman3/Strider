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
    
    @State private var isCustomShareViewPresented = false
    
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
            HapticFeedbackProvider.impact()
            isCreateViewPresented = true
        }) {
            Image(systemName: "plus.circle")
                .font(.title2)
                .foregroundStyle(.white)
        })
        .fullScreenCover(isPresented: $isCreateViewPresented) {
            CreateChallengeView(isPresented: $isCreateViewPresented)
                .environmentObject(challengeViewModel)
        }
        .fullScreenCover(isPresented: $challengeViewModel.presentShareController, content: {
            CustomShareView(share: $challengeViewModel.share, shareURL: $challengeViewModel.shareURL, details: $challengeViewModel.details, isPresented: $challengeViewModel.presentShareController)
        })
        .background(.black)
        .onAppear {
            Task {
                await challengeViewModel.loadPendingChallenges()
            }
        }
    }
}
