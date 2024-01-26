//
//  myPedometerApp.swift
//  myPedometer
//
//  Created by Sam Roman on 1/24/24.
//

import SwiftUI
import SwiftData

@main
struct myPedometerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        let context = persistenceController.container.viewContext
        let dataStore = PedometerDataStore(context: context)

        let pedometerDataProvider: PedometerDataProvider
        #if targetEnvironment(simulator)
        pedometerDataProvider = MockPedometerDataProvider()
        #else
        pedometerDataProvider = PedometerManager(context: context, dataStore: dataStore)
        #endif

        let providerWrapper = PedometerProviderWrapper(provider: pedometerDataProvider)

        return WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, context)
                .environmentObject(dataStore)
                .environmentObject(providerWrapper) // Pass the provider wrapper
        }
    }
}


