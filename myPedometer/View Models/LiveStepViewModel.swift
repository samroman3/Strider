//
//  LiveStepViewModel.swift
//  myPedometer
//
//  Created by Sam Roman on 1/24/24.
//

import SwiftUI

class LiveStepViewModel: ObservableObject {
    @Published var liveStepCount: Int = 0
    private var pedometerManager: PedometerManager
    private let calendar = Calendar.current

    init(pedometerManager: PedometerManager) {
        self.pedometerManager = pedometerManager
        startLiveStepUpdates()
    }

    private func startLiveStepUpdates() {
        pedometerManager.startPedometerUpdates { [weak self] stepCount in
            DispatchQueue.main.async {
                // Only update if it's today
                if self?.isToday() ?? false {
                    self?.liveStepCount = stepCount
                }
            }
        }
    }

   func isToday() -> Bool {
        return calendar.isDateInToday(Date())
    }
}
