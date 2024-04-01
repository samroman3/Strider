//
//  AwardsView.swift
//  myPedometer
//
//  Created by Sam Roman on 3/13/24.
//

import SwiftUI

struct AwardsView: View {
    @EnvironmentObject var viewModel: StepDataViewModel
    @State private var animateToGold: [Bool]
    @Environment(\.colorScheme) var colorScheme

    init() {
        // Initialize animation states based on the number of awards
        self._animateToGold = State(initialValue: Array(repeating: false, count: 7))
    }

    var body: some View {
        ScrollView {
            VStack {
                SectionView(sectionTitle: "DAILY STEPS", personalBest: "" /*"Personal best: \(viewModel.stepsRecord)"*/, items: stepAwards(), animateToGold: $animateToGold)
                SectionView(sectionTitle: "DAILY CALORIES", personalBest: "" /*"Personal best: \(Int(viewModel.calRecord))"*/, items: calorieAwards(), animateToGold: $animateToGold)
            }
        }
        .background(colorScheme == .dark ? .black : .white)

        .onAppear {
            // Animate each award to gold one by one
            for index in animateToGold.indices {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        animateToGold[index] = true
                    }
                    // After the animation to gold, determine if it needs to revert to gray
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1 + 1) {
                        withAnimation(.easeIn(duration: 0.2)) {
                            animateToGold[index] = remain(index: index)
                        }
                    }
                }
            }
        }
    }

    private func remain(index: Int) -> Bool {
        switch index {
        case 0:
            return (viewModel.todaySteps >= viewModel.dailyStepGoal)
        case 1:
            return viewModel.fiveKStepsReached
        case 2:
            return viewModel.tenKStepsReached
        case 3:
            return viewModel.twentyKStepsReached
        case 4:
            return viewModel.thirtyKStepsReached
        case 5:
            return viewModel.fortyKStepsReached
        case 6:
            return viewModel.fiftyKStepsReached
        default:
            return false
        }
    }

    
    private func stepAwards() -> [(title: String, imageName: String, count: String)] {
        return [
            ("Steps Goal Achieved", viewModel.todaySteps >= viewModel.dailyStepGoal ? "shoe.circle.fill" : "shoe.circle", viewModel.dailyStepGoal.formatNumber()),
            ("5K steps", viewModel.fiveKStepsReached ? "5.circle.fill" : "5.circle", "5,000"),
            ("10K steps", viewModel.tenKStepsReached ? "10.circle.fill" : "10.circle", "10,000"),
            ("20K steps", viewModel.twentyKStepsReached ? "20.circle.fill" : "20.circle", "20,000"),
            ("30K steps", viewModel.thirtyKStepsReached ? "30.circle.fill" : "30.circle", "30,000"),
            ("40K steps", viewModel.fortyKStepsReached ? "40.circle.fill" : "40.circle", "40,000"),
            ("50K steps", viewModel.fiftyKStepsReached ? "50.circle.fill" : "50.circle", "50,000")
        ]
    }
    
    private func calorieAwards() -> [(title: String, imageName: String, count: String)] {
        return [
            ("Calorie Goal Achieved", Int(viewModel.caloriesBurned) >= viewModel.dailyCalGoal ? "flame.circle.fill" : "flame.circle", viewModel.dailyCalGoal.formatNumber()),
            ("500 cals", viewModel.fiveHundredCalsReached ? "flame.circle.fill" : "flame.circle", "500"),
            ("1000 cals", viewModel.thousandCalsReached ? "flame.circle.fill" : "flame.circle", "1,000")
        ]
    }
    
}

struct SectionView: View {
    let sectionTitle: String
    let personalBest: String
    let items: [(title: String, imageName: String, count: String)]
    @Binding var animateToGold: [Bool]
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            HeaderView(sectionTitle: sectionTitle, personalBest: personalBest)
            AwardGrid(items: items, animateToGold: $animateToGold)
        }
        .background(.clear)
    }
}

struct HeaderView: View {
    let sectionTitle: String
    let personalBest: String
    
    var body: some View {
        HStack {
            Text(sectionTitle)
                .font(.headline)
                .foregroundColor(.gray)
            Spacer()
            Text(personalBest)
                .font(.footnote)
                .foregroundColor(.gray)
        }
        .padding()
    }
}

struct LifetimeStepsView: View {
    @State var lifeTimeSteps: Int
    
    var body: some View {
        VStack(alignment: .center) {
            Text("STRIDER STEPS")
                .font(.headline)
                .foregroundColor(.gray)
            Text("\(lifeTimeSteps, specifier: "%.0f") total steps")
                .font(.title)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.black)
    }
}

// Existing AwardGrid struct unchanged

extension Int {
    func formatNumber() -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}


// Award Grid Component
struct AwardGrid: View {
    let items: [(title: String, imageName: String, count: String)]
    let tileWidth: CGFloat = 115
    let tileHeight: CGFloat = 150
    @Binding var animateToGold: [Bool] // Accept a binding to the animation state

    func achievementBackground(isAchieved: Bool) -> some View {
        let goldGradient = LinearGradient(gradient: Gradient(colors: [.yellow, .orange, .yellow]), startPoint: .topLeading, endPoint: .bottomTrailing)
        let darkGray = Color(red: 94 / 255, green: 94 / 255, blue: 94 / 255)
        let grayGradient = LinearGradient(gradient: Gradient(colors: [.gray, darkGray]), startPoint: .topLeading, endPoint: .bottomTrailing)
        
        return RoundedRectangle(cornerRadius: 10)
            .fill(isAchieved ? goldGradient : grayGradient)
            .shadow(color: isAchieved ? .yellow : .clear, radius: 10, x: 0, y: 10)
    }

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 15) {
            ForEach(items.indices, id: \.self) { index in
                let isAchieved = animateToGold[index]
                VStack {
                    Image(systemName: items[index].imageName)
                        .font(.largeTitle)
                        .foregroundColor(isAchieved ? .white : .gray) // Use animateToGold state for color
                    Text(items[index].title)
                        .foregroundColor(isAchieved ? .black : .white)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                    Text(items[index].count)
                        .foregroundColor(.white)
                        .padding(.top, 4)
                }
                .padding([.horizontal])
                .frame(width: tileWidth, height: tileHeight)
                .background(achievementBackground(isAchieved: isAchieved)) // Use animateToGold for background
                .cornerRadius(10)
            }
        }
    }
}


// Preview
struct AwardsView_Previews: PreviewProvider {
    static var previews: some View {
        AwardsView()
    }
}
