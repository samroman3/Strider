//
//  UserSettingsManager.swift
//  myPedometer
//
//  Created by Sam Roman on 3/14/24.
//

import SwiftUI
import CoreData
import AuthenticationServices
import CloudKit

class UserSettingsManager: ObservableObject {
    static let shared = UserSettingsManager()

    
    var context: NSManagedObjectContext?
    private var user: User?
    
    @Published var photoData: Data?
    @Published var lifetimeSteps: Int = 0
    @Published var stepsRecord: Int = 0
    @Published var calorieRecord: Int = 0
    @Published var userName: String = ""

    
      @Published var hasCompletedOnboarding: Bool {
          didSet { updateUserDefaults(key: "hasCompletedOnboarding", value: hasCompletedOnboarding) }
      }
      
      @Published var iCloudConsentGiven: Bool {
          didSet { updateUbiquitousKeyValueStore(key: "iCloudConsentGiven", value: iCloudConsentGiven) }
      }
      
      @Published var hasSignedIn: Bool {
          didSet { updateUserDefaults(key: "hasSignedIn", value: hasSignedIn) }
      }
      
      @Published var dailyStepGoal: Int {
          didSet { updateUserDefaults(key: "dailyStepGoal", value: dailyStepGoal) }
      }
      
      @Published var dailyCalGoal: Int {
          didSet { updateUserDefaults(key: "dailyCalGoal", value: dailyCalGoal) }
      }
      
     init() {
          hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
          iCloudConsentGiven = UserDefaults.standard.bool(forKey: "iCloudConsentGiven")
          hasSignedIn = UserDefaults.standard.bool(forKey: "hasSignedIn")
          dailyStepGoal = UserDefaults.standard.integer(forKey: "dailyStepGoal")
          dailyCalGoal = UserDefaults.standard.integer(forKey: "dailyCalGoal")
      }
      
      private func updateUserDefaults<T>(key: String, value: T) {
          UserDefaults.standard.set(value, forKey: key)
      }
      
      private func updateUbiquitousKeyValueStore<T>(key: String, value: T) {
          NSUbiquitousKeyValueStore.default.set(value, forKey: key)
          NSUbiquitousKeyValueStore.default.synchronize()
      }
    
    func checkiCloudAvailability(completion: @escaping (Bool) -> Void) {
            CKContainer.default().accountStatus { accountStatus, error in
                DispatchQueue.main.async {
                    if let error = error {
                        // Handle any errors here, possibly using an error presentation
                        print("Error checking iCloud account status: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        switch accountStatus {
                        case .available:
                            completion(true)
                        default:
                            // Inform the user that they are not signed into iCloud
                            completion(false)
                        }
                    }
                }
            }
        }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }


    @objc private func ubiquitousKeyValueStoreDidChange(_ notification: Notification) {
        // Handle changes as needed, for example, reload flags
    }

    
    //Mark: Key Value iCloud Markers
    
    func saveOnboardingCompletedFlag(isCompleted: Bool) {
        NSUbiquitousKeyValueStore.default.set(isCompleted, forKey: "onboardingCompleted")
        NSUbiquitousKeyValueStore.default.synchronize() 
    }

    func saveConsentFlag(isGiven: Bool) {
        NSUbiquitousKeyValueStore.default.set(isGiven, forKey: "consentGiven")
        NSUbiquitousKeyValueStore.default.synchronize()
    }
    
    func isOnboardingCompleted() -> Bool {
        return NSUbiquitousKeyValueStore.default.bool(forKey: "onboardingCompleted")
    }

    func isConsentGiven() -> Bool {
        return NSUbiquitousKeyValueStore.default.bool(forKey: "consentGiven")
    }

    func loadUserSettings() {
        user = fetchOrCreateUserSettings()
        if let user = user {
            DispatchQueue.main.async {
                // Assign the new properties with values from CoreData
                self.photoData = user.photoData
                self.lifetimeSteps = Int(user.lifetimeSteps)
                self.stepsRecord = Int(user.stepsRecord)
                self.calorieRecord = Int(user.calorieRecord)
                self.userName = user.userName ?? ""
            }
        }
    }
    
    func saveUserDetails(photoData: Data, lifetimeSteps: Int, stepsRecord: Int, calorieRecord: Int, userName: String) {
        let settings = fetchOrCreateUserSettings()
        settings.photoData = photoData
        settings.lifetimeSteps = Int32(lifetimeSteps)
        settings.stepsRecord = Int32(stepsRecord)
        settings.calorieRecord = Int32(calorieRecord)
        settings.userName = userName
        saveContext()
    }
    func saveProfileDetails(image: UIImage?, userName: String) {
        let user = fetchOrCreateUserSettings()
        
        // Convert UIImage to Data for storage
        if let image = image {
            user.photoData = image.jpegData(compressionQuality: 1.0)
        }
        
        user.userName = userName
                
        saveContext()
    }
    
    func uploadProfileImage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 1.0) else { return }
        DispatchQueue.main.async {
            let user = self.fetchOrCreateUserSettings()
            user.photoData = imageData
            self.saveContext()
        }
    }

    private func fetchOrCreateUserSettings() -> User {
        if let user = user {
            return user
        } else {
            let request: NSFetchRequest<User> = User.fetchRequest()
            do {
                let results = try context?.fetch(request)
                if let existingUser = results?.first {
                    user = existingUser
                    return existingUser
                }
            } catch {
                print("Error fetching UserSettings: \(error)")
            }
            let newUser = User(context: context!)
            user = newUser
            return newUser
        }
    }
    
private func saveContext() {
    if ((context?.hasChanges) != nil) {
        do {
            try context?.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}
    
    func checkAppleIDCredentialState(userID: String, completion: @escaping (Bool) -> Void) {
           let appleIDProvider = ASAuthorizationAppleIDProvider()
           appleIDProvider.getCredentialState(forUserID: userID) { (credentialState, error) in
               DispatchQueue.main.async {
                   switch credentialState {
                   case .authorized:
                       // The user is signed in with Apple
                       completion(true)
                   case .revoked, .notFound:
                       // The user is not signed in, or the credential has been revoked
                       completion(false)
                   default:
                       // Handle other cases
                       completion(false)
                   }
               }
           }
       }
    func updateUserAfterSignInWithApple(userID: String, fullName: String?) {
        DispatchQueue.main.async {
            self.user?.appleId = userID
            self.userName = fullName ?? self.userName
            
            self.hasSignedInWithApple = true
            
            self.saveContext()
        }
    }

    @Published var hasSignedInWithApple: Bool = false

    // This would be a new method to save the `hasSignedInWithApple` flag to the iCloud Key-Value Store
    func saveAppleSignInFlag() {
        NSUbiquitousKeyValueStore.default.set(hasSignedInWithApple, forKey: "hasSignedInWithApple")
        NSUbiquitousKeyValueStore.default.synchronize()
    }
    
}

// Helper extension to convert NSData to UIImage
extension NSData {
var uiImage: UIImage? { UIImage(data: self as Data) }
}
