//
//  CustomShareView.swift
//  myPedometer
//
//  Created by Sam Roman on 3/18/24.
//

import SwiftUI
import CloudKit
import LinkPresentation

struct CustomShareView: View {
    @Binding var share: CKShare?
    @Binding var shareURL: URL?
    @Binding var details: ChallengeDetails?
    @Binding var isPresented: Bool
    
    @State private var isSharingPresented = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Share Your Challenge!")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 20)
            
            if let goalSteps = details?.goalSteps, let endTime = details?.endTime {
                VStack {
                    Text("Challenge: \(goalSteps) steps")
                        .fontWeight(.medium)
                    Text("End Time: \(endTime.formatted())")
                        .fontWeight(.medium)
                }
                .padding()
                .background(AppTheme.darkerGray)
                .cornerRadius(12)
                .shadow(radius: 3)
            }
            
            Button(action: {
                isSharingPresented = true
            }) {
                Text("Share Challenge")
                    .bold()
                    .foregroundColor(.white)
                    .padding()
                    .background(AppTheme.purpleGradient)
                    .cornerRadius(12)
                    .shadow(radius: 3)
            }
            
            Button("Close") {
                isPresented = false
            }
            .foregroundColor(.red)
            .padding()
            
        }
        .padding()
        .sheet(isPresented: $isSharingPresented, onDismiss: {
            isPresented = false
            print("Dismissed share sheet")
        }) {
            if let shareURL = shareURL {
                ActivityView(activityItems: [AnySharingItem(source: shareURL)], applicationActivities: nil)
            }
        }
        .background(AppTheme.purpleGradient.opacity(0.03))
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
