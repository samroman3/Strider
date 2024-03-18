//
//  BarGoalView.swift
//  myPedometer
//
//  Created by Sam Roman on 3/9/24.
//
import SwiftUI

struct BarGoalView: View {
    @EnvironmentObject var viewModel: StepDataViewModel
    @State private var animatedValue: Int = 0
    @State private var goalValue: Double = 0
    var challenge: Bool = false
    var layers: Int = 10
    var alignLeft: Bool
    
    private func animateProgress() {
        // Choose the correct goal and current value based on the challenge flag and alignment.
        let targetValue = challenge ? (alignLeft ? Double(viewModel.theirSteps) : Double(viewModel.todaySteps)) : (alignLeft ? Double(viewModel.caloriesBurned) : Double(viewModel.todaySteps))
        goalValue = challenge ? Double(viewModel.challengeGoal) : (alignLeft ? Double(viewModel.dailyCalGoal) : Double(viewModel.dailyStepGoal))
        
        if goalValue > 0, !targetValue.isNaN, !targetValue.isInfinite {
            let percentage = targetValue / goalValue
            let nextPercentile = ceil(percentage * Double(layers)) / Double(layers)
            withAnimation(.easeInOut(duration: 2)) {
                if percentage >= 1.0 {
                    animatedValue = Int(goalValue)
                } else {
                    animatedValue = Int(percentage * Double(goalValue - 1))
                }
            }
        } else {
            animatedValue = 0
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ForEach(0..<layers, id: \.self) { layer in
                    BarView(layer: layer, maxLayers: layers, goal: Int(goalValue), current: animatedValue, alignLeft: alignLeft, challenge: challenge)
                        .frame(height: (geometry.size.height) / CGFloat(layers))
                }
            }
        }
        .onAppear { animateProgress() }
        .onChange(of: viewModel.todaySteps) { _ in animateProgress() }
        .onChange(of: viewModel.caloriesBurned) { _ in animateProgress() }
        // Add change listeners for challenge properties if challenge mode is on
        .onChange(of: viewModel.theirSteps) { _ in if challenge { animateProgress() } }
        .onChange(of: viewModel.challengeGoal) { _ in if challenge { animateProgress() } }
    }
}




struct BarView: View {
    var layer: Int
    var maxLayers: Int
    var goal: Int
    var current: Int
    var alignLeft: Bool
    var challenge: Bool
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            // Calculate the width of the bar at this layer, with larger bars at the top
            let baseWidth = screenWidth * 0.1 // Width of the smallest bar at the bottom
            let increment = (screenWidth - baseWidth) / CGFloat(maxLayers - 1)
            let barWidth = baseWidth + increment * CGFloat(maxLayers - layer - 1)
            
            //            // Calculate the progress
            //            let totalProgress = CGFloat(current) / CGFloat(goal)
            //            let layerIndex = CGFloat(maxLayers - layer - 1) // Reverse the layer index for bottom-to-top fill
            //            let layersFilledCompletely = CGFloat(totalProgress * CGFloat(maxLayers))
            //
            //            // Determine if the layer should be filled based on progress
            //            let isLayerFilled = layerIndex < layersFilledCompletely
            
            // Calculate the progress
            let totalProgress = CGFloat(current) / CGFloat(goal)
            let layerProgress = 1.0 / CGFloat(maxLayers) // The progress each layer represents
            let layerIndex =  CGFloat(maxLayers - layer - 1)
            
            // Determine if the layer should be filled based on progress
            // If current is less than the goal, we subtract a small amount from totalProgress
            // to prevent the last bar from filling
            let adjustedProgress = current < goal ? floor(totalProgress * CGFloat(maxLayers)) / CGFloat(maxLayers) : 1.0
            let isLayerFilled = layerIndex < CGFloat(maxLayers) * adjustedProgress
            
            ZStack(alignment: .leading) {
                // Background of the bar
                Rectangle()
//                    .fill(grayMaterialGradient())
                    .frame(width: barWidth)
                    .foregroundStyle(Material.ultraThin)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                    .clipShape(
                        RoundedCorners(
                            topLeft: alignLeft ? 0 : 10,
                            topRight: alignLeft ? 10 : 0,
                            bottomLeft: alignLeft ? 0 : 10,
                            bottomRight: alignLeft ? 10 : 0
                        )
                    )
                
                
                // Fill of the bar, applied if within the completed progress
                if isLayerFilled {
                    Rectangle()
                        .fill(layerFill(layer: layer))
                        .frame(width: barWidth)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                        .animation(Animation.linear(duration: 0.5).delay(0.05 * Double(maxLayers - layer - 1)))
                        .clipShape(
                            RoundedCorners(
                                topLeft: alignLeft ? 0 : 10,
                                topRight: alignLeft ? 10 : 0,
                                bottomLeft: alignLeft ? 0 : 10,
                                bottomRight: alignLeft ? 10 : 0
                            )
                        )
                }
            }
            .padding(.top)
            .padding(alignLeft ? .trailing : .leading, screenWidth - barWidth)
        }
    }
    
    private func layerFill(layer: Int) -> LinearGradient {
        let gradientColors = alignLeft ? [Color.yellow, Color.orange, Color.red] : [Color.green, Color.blue, Color.mint]
        let challengeColors = [Color.blue, Color.purple]
        
        return LinearGradient(gradient: Gradient(colors: challenge ? challengeColors : gradientColors), startPoint: .leading, endPoint: .trailing)
    }
    
    private func grayMaterialGradient() -> LinearGradient {
        let darkGray = Color(red: 94 / 255, green: 94 / 255, blue: 94 / 255)
        let darkerGray = Color(red: 28 / 255, green: 28 / 255, blue: 28 / 255)
        let order = alignLeft ? [darkerGray, darkGray] : [darkerGray]
        return LinearGradient(gradient: Gradient(colors: [darkerGray]), startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}


struct RoundedCorners: Shape {
    var topLeft: CGFloat = 0.0
    var topRight: CGFloat = 0.0
    var bottomLeft: CGFloat = 0.0
    var bottomRight: CGFloat = 0.0
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.size.width
        let height = rect.size.height
        let tr = min(min(self.topRight, height/2), width/2)
        let tl = min(min(self.topLeft, height/2), width/2)
        let bl = min(min(self.bottomLeft, height/2), width/2)
        let br = min(min(self.bottomRight, height/2), width/2)
        
        path.move(to: CGPoint(x: width / 2.0, y: 0))
        path.addLine(to: CGPoint(x: width - tr, y: 0))
        path.addArc(center: CGPoint(x: width - tr, y: tr), radius: tr,
                    startAngle: Angle(degrees: -90), endAngle: Angle(degrees: 0), clockwise: false)
        path.addLine(to: CGPoint(x: width, y: height - br))
        path.addArc(center: CGPoint(x: width - br, y: height - br), radius: br,
                    startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 90), clockwise: false)
        path.addLine(to: CGPoint(x: bl, y: height))
        path.addArc(center: CGPoint(x: bl, y: height - bl), radius: bl,
                    startAngle: Angle(degrees: 90), endAngle: Angle(degrees: 180), clockwise: false)
        path.addLine(to: CGPoint(x: 0, y: tl))
        path.addArc(center: CGPoint(x: tl, y: tl), radius: tl,
                    startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 270), clockwise: false)
        path.closeSubpath()
        
        return path
    }
}
