//
//  HourlyStepsChart.swift
//  myPedometer
//
//  Created by Sam Roman on 1/28/24.
//

import SwiftUI
import Charts

struct HourlyStepsChart: View {
    let hourlySteps: [HourlySteps]
    let averageHourlySteps: [HourlySteps]
    
    var body: some View {
        if #available(iOS 16.0, *) {
            Chart {
                ForEach(hourlySteps, id: \.hour) { step in
                    BarMark(
                        x: .value("Hour", step.hour),
                        y: .value("Today", step.steps)
                    )
                    .foregroundStyle(.orange)
                }
                ForEach(averageHourlySteps, id: \.hour) { step in
                    BarMark(
                        x: .value("Hour", step.hour),
                        y: .value("Average", step.steps)
                    )
                    .foregroundStyle(.gray)
                }
            }
            .chartXAxisLabel("Hour")
            .chartXAxis {
                AxisMarks(values: .stride(by: 1)) { value in
                    if let hour = value.as(Int.self) {
                        switch hour {
                        case 0, 23:
                            AxisValueLabel("12AM")
                        case 12:
                            AxisValueLabel("12PM")
                        default:
                            AxisValueLabel("")
                        }
                    }
                }
            }
        }
    }
}


let mockHourlySteps = (0...23).map { HourlySteps(hour: $0, steps: Int.random(in: 1000...5000)) }
let mockAverageHourlySteps = (0...23).map { HourlySteps(hour: $0, steps: 3000) }

#Preview {
    HourlyStepsChart(hourlySteps: mockHourlySteps, averageHourlySteps: mockAverageHourlySteps)
}


