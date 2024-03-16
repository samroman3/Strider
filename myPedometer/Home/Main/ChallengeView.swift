//
//  ChallengeView.swift
//  myPedometer
//
//  Created by Sam Roman on 3/13/24.
//

import SwiftUI

struct ChallengeView: View {
    // Dummy data
    let mySteps: Int = 10300
    let theirSteps: Int = 5989
    let goal: Int = 10000

    var body: some View {
        VStack {
            Text("GOAL: \(goal)")
                .font(.title2)
                .foregroundColor(.white)
                .padding(.top, 4)

            Text("ENDS: Today @ 10 PM")
                .foregroundColor(.gray)
                .padding(.bottom, 30)

            HStack(spacing: 0) {
                // Bar for the other participant
                BarGoalView(challenge: true, alignLeft: false)
                
                // Divider between the bars
                Divider()
                    .background(Color.white)

                // Bar for the current user
                BarGoalView(challenge: true, alignLeft: true)
            }

            // User info and steps
            HStack {
                VStack {
                    // Other participant info and steps
                    Text("\(mySteps)")
                        .font(.title)
                        .foregroundColor(.white)
                    Text("Me")
                        .foregroundColor(.gray)
                }
                Spacer()
                VStack {
                    // Current user info and steps
                    Text("\(theirSteps)")
                        .font(.title)
                        .foregroundColor(.white)
                    Text("Max")
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
        }
        .background(Color.black)
    }
}

import SwiftUI

struct ChallengeBarGoalView: View {
    var progress: Double
    var alignLeft: Bool
    var layers: Int = 10 // The number of bars to display
    
    // Define the gradient to be used for filling the bars
    let fillGradient = LinearGradient(
        gradient: Gradient(colors: [.white, .blue, .purple]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    var body: some View {
        GeometryReader { geometry in
            let barWidth = geometry.size.width / CGFloat(layers)
            let fillHeight = geometry.size.height * CGFloat(progress)
            
            ZStack(alignment: alignLeft ? .bottom : .top) {
                ForEach(0..<layers) { layer in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(fillGradient)
                        .frame(width: barWidth, height: geometry.size.height / CGFloat(layers))
                        // The bars are positioned to fill from the bottom or from the top based on alignLeft
                        .offset(y: alignLeft ? 0 : (fillHeight - geometry.size.height / CGFloat(layers) * CGFloat(layer + 1)))
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: alignLeft ? .bottomLeading : .bottomTrailing)
        }
    }
}

// Preview for the ChallengeBarGoalView
struct ChallengeBarGoalView_Previews: PreviewProvider {
    static var previews: some View {
        ChallengeBarGoalView(progress: 0.5, alignLeft: true)
            .frame(width: 100, height: 300)
            .previewLayout(.sizeThatFits)
    }
}


// Preview for the ChallengeView
struct ChallengeView_Previews: PreviewProvider {
    static var previews: some View {
        ChallengeView()
    }
}

