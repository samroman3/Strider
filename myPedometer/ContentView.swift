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
    
    private var stepDataViewModel: StepDataViewModel
    @State private var selectedDate: Date = Date()
    
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        let dateManager = DateManager(context: context)
        
        //Setup MockPedometer for test environment only
#if targetEnvironment(simulator)
        let pedometerDataProvider: PedometerDataProvider = MockPedometerDataProvider()
#else
        let pedometerDataProvider: PedometerDataProvider = PedometerManager(context: context, dateManager: dateManager)
#endif
        
        let dataStore = PedometerDataStore(context: context, pedometerManager: pedometerDataProvider)
        
        stepDataViewModel = StepDataViewModel(pedometerDataProvider: pedometerDataProvider, dataStore: dataStore)
        
    }
    
    var body: some View {
        HomeView(viewModel: stepDataViewModel)
    }
}



