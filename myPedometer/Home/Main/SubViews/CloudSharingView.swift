//
//  CloudSharingView.swift
//  myPedometer
//
//  Created by Sam Roman on 3/18/24.
//

import SwiftUI
import CloudKit
import UIKit

struct CloudSharingControllerRepresentable: UIViewControllerRepresentable {
    var share: CKShare
    var container: CKContainer
    var rootRecord: CKRecord
    
    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: container)
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UICloudSharingControllerDelegate {
        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            <#code#>
        }
        
        var parent: CloudSharingControllerRepresentable
        
        init(_ parent: CloudSharingControllerRepresentable) {
            self.parent = parent
        }
        
        func itemTitle(for csc: UICloudSharingController) -> String? {
            return "Challenge"
        }
    }
}
