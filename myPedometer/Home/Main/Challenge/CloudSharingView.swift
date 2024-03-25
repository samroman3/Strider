//
//  CloudSharingView.swift
//  myPedometer
//
//  Created by Sam Roman on 3/18/24.
//

import SwiftUI
import CloudKit
import LinkPresentation

//struct CloudSharingControllerRepresentable: UIViewControllerRepresentable {
//    var share: CKShare?
//    var container: CKContainer?
//    var shareURL: URL?
//    
//    @EnvironmentObject var viewModel: ChallengeViewModel
//    
//    func makeUIViewController(context: Context) -> UICloudSharingController {
//        let controller = UICloudSharingController(share: share!, container: container!)
//        controller.availablePermissions = [.allowPrivate, .allowReadWrite]
//        controller.delegate = context.coordinator
//        return controller
//    }
//    
//    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {}
//    
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self)
//    }
//    
//    class Coordinator: NSObject, UICloudSharingControllerDelegate {
//        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
//            //
//        }
//        
//        var parent: CloudSharingControllerRepresentable
//        
//        init(_ parent: CloudSharingControllerRepresentable) {
//            self.parent = parent
//        }
//        
//        func itemTitle(for csc: UICloudSharingController) -> String? {
//            return "Share Challenge"
//        }
//    }
//}

struct CustomShareView: View {
    @Binding var share: CKShare?
    @Binding var shareURL: URL?
    @Binding var details: ChallengeDetails?
    
    @State private var isSharingPresented = false
    
    var body: some View {
        VStack {
            // Display challenge details
            if let goalSteps = details?.goalSteps, let endTime = details?.endTime {
                Text("Challenge: \(goalSteps) steps")
                Text("End Time: \(endTime.formatted())")
            }
            
            Button("Share Challenge") {
                isSharingPresented = true
            }
            .sheet(isPresented: $isSharingPresented, onDismiss: {
                print("Dismissed share sheet")
            }) {
                // Use ActivityView for sharing
                if let shareURL = shareURL {
                    ActivityView(activityItems: [AnySharingItem(source: shareURL)], applicationActivities: nil)
                }
            }
        }
    }
}

class AnySharingItem: NSObject, UIActivityItemSource {
    let source: URL
    
    init(source: URL) {
        self.source = source
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        source
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        source
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        "Join My Challenge on Strider!"
    }
    
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = "Join My Challenge on Strider!"
        metadata.originalURL = source
        //TODO: Detailed meta data, user icon, app icon, goal and time
//        metadata.iconProvider
        return metadata
    }
}


struct ActivityView: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]?
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityView>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityView>) {}
}
