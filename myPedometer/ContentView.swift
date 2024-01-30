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
    var pedometerDataProvider: PedometerDataProvider & PedometerDataObservable
    
    var body: some View {
        HomeView(viewModel: StepDataViewModel(pedometerDataProvider: pedometerDataProvider))
    }
}


