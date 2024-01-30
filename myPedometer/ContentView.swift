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
    @StateObject private var viewModel: StepDataViewModel

        init(pedometerDataProvider: PedometerDataProvider & PedometerDataObservable) {
            _viewModel = StateObject(wrappedValue: StepDataViewModel(pedometerDataProvider: pedometerDataProvider))
        }
    
    var body: some View {
           HomeView(viewModel: viewModel)
            .alert(item: $viewModel.error) { error in
                        Alert(
                            title: Text("Error"),
                            message: Text(error.localizedMessage),
                            dismissButton: .default(Text("OK"))
                        )
                    }
       }
}


