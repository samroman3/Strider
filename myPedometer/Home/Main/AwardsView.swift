//
//  AwardsView.swift
//  myPedometer
//
//  Created by Sam Roman on 3/13/24.
//

import SwiftUI
import SwiftUI

struct AwardsView: View {
    @EnvironmentObject var viewModel: StepDataViewModel
    
    var body: some View {
            ScrollView {
                VStack() {
                    SectionView(sectionTitle: "DAILY STEPS", personalBest: "Personal best: \(viewModel.dailyStepGoal)", items: stepAwards())
                    
                    SectionView(sectionTitle: "DAILY CALORIES", personalBest: "Personal best: \(Int(viewModel.caloriesBurned))", items: calorieAwards())
                    
                    LifetimeStepsView(lifeTimeSteps: $viewModel.lifeTimeSteps)
                }
            }
        .background(.black)
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
    
    var body: some View {
        VStack {
            HeaderView(sectionTitle: sectionTitle, personalBest: personalBest)
            AwardGrid(items: items)
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
    @Binding var lifeTimeSteps: Int
    
    var body: some View {
        VStack(alignment: .center) {
            Text("LIFETIME STEPS")
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
    
    // Define uniform tile size
     let tileWidth: CGFloat = 115
     let tileHeight: CGFloat = 150
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: 3), spacing: 15) {
            ForEach(items, id: \.title) { item in
                VStack {
                    Image(systemName: item.imageName)
                        .font(.largeTitle)
                        .foregroundColor(item.imageName.contains("fill") ? .black : .yellow)
                    Text(item.title)
                        .foregroundColor(item.imageName.contains("fill") ? .black : .white)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                    Text(item.count)
                        .foregroundColor(item.imageName.contains("fill") ? .black : .gray)
                        .padding(.top, 4)
                }
                .padding([.horizontal])
                .frame(width: tileWidth, height: tileHeight)
                .background(achievementBackground(isAchieved: item.imageName.contains("fill")))
                .cornerRadius(10)
            }.padding()
        }
    }
    // Function to determine the background based on achievement
      func achievementBackground(isAchieved: Bool) -> some View {
          // Gold and shiny background for achieved awards
          let goldGradient = LinearGradient(gradient: Gradient(colors: [.yellow, .orange, .yellow]), startPoint: .topLeading, endPoint: .bottomTrailing)
          // More subdued background for not achieved
          let darkGray = Color(red: 94 / 255, green: 94 / 255, blue: 94 / 255)
          let grayGradient = LinearGradient(gradient: Gradient(colors: [.gray, darkGray]), startPoint: .topLeading, endPoint: .bottomTrailing)
          
          return RoundedRectangle(cornerRadius: 10)
              .fill(isAchieved ? goldGradient : grayGradient)
              .shadow(color: isAchieved ? .yellow : .clear, radius: 10, x: 0, y: 10) // Optional: Add a glow effect to achieved awards
              .overlay(
                  isAchieved ?
                      RoundedRectangle(cornerRadius: 10)
                      .stroke(Color.black, lineWidth: 0.5) // Adds a subtle border to achieved awards for better contrast
                      : nil
              )
      }
}

// Preview
struct AwardsView_Previews: PreviewProvider {
    static var previews: some View {
        AwardsView()
    }
}
