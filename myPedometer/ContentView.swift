//
//  ContentView.swift
//  myPedometer
//
//  Created by Sam Roman on 1/24/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    private var stepViewModel: StepDataViewModel
    private var liveStepViewModel: LiveStepViewModel

    init() {
        let context = PersistenceController.shared.container.viewContext
        let dateManager = DateManager(context: context)
        let pedometerManager = PedometerManager(context: context, dateManager: dateManager)
        let dataStore = PedometerDataStore(context: context, pedometerManager: pedometerManager)
        
        stepViewModel = StepDataViewModel(dateManager: dateManager, dataStore: dataStore)
        liveStepViewModel = LiveStepViewModel(pedometerManager: pedometerManager)
    }

    var body: some View {
        HomeView(viewModel: stepViewModel, liveStepViewModel: liveStepViewModel)
    }
}



