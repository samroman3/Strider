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
    @StateObject private var stepDataViewModel: StepDataViewModel

        init(pedometerDataProvider: PedometerDataProvider & PedometerDataObservable) {
            _stepDataViewModel = StateObject(wrappedValue: StepDataViewModel(pedometerDataProvider: pedometerDataProvider))
        }
    
    var body: some View {
        CustomTabBarView()
            .environmentObject(stepDataViewModel)
    }
}


