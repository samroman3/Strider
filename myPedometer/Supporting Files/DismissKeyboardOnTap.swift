//
//  DismissKeyboardOnTap.swift
//  myPedometer
//
//  Created by Sam Roman on 3/23/24.
//

import SwiftUI

extension View {
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
