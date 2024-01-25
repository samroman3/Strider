//
//  DetailView.swift
//  myPedometer
//
//  Created by Sam Roman on 1/24/24.
//

import SwiftUI

struct DetailView: View {
    let dayLog: DailyLog
    
    var body: some View {
        Text("\(dayLog.date ?? Date(), formatter: itemFormatter)")
        Text("Steps: \(dayLog.totalSteps)")
    }
}

//#Preview {
//    DetailView()
//}
