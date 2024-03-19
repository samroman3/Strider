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
    
    @Published var userRecord: CKRecord?
    
    @Published var cloudKitRecordName: String? {
        didSet {
            updateUserDefaults(key: "CloudKitRecordName", value: cloudKitRecordName)
        }
    }

    
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
//         cloudKitRecordName = UserDefaults.standard.string(forKey: "CloudKitRecordName")

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
    
    func getCurrentUserRecordID(completion: @escaping (Result<CKRecord.ID, Error>) -> Void) {
        CKContainer.default().fetchUserRecordID { recordID, error in
            DispatchQueue.main.async {
                if let recordID = recordID {
                    completion(.success(recordID))
                } else if let error = error {
                    completion(.failure(error))
                } else {
                    let error = NSError(domain: "CloudKitError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown error fetching user record ID"])
                    completion(.failure(error))
                }
            }
        }
    }

    func setUserCloudKitRecord(){
        self.getCurrentUserRecordID { [weak self] result in
            switch result {
            case .success(let recordID):
                // Use the fetched recordID to create or update a User CKRecord
                // This helps ensure that the User CKRecord is associated with the correct iCloud user
                let userRecord = self?.user?.toCKRecord(recordID: recordID.recordName)
                self?.cloudKitRecordName = recordID.recordName
                
            case .failure(let error):
                // Handle error 
                print("Error fetching current user's CloudKit record ID: \(error.localizedDescription)")
            }
        }
    }
    
    func updateOrCreateChallenge(from cloudKitRecord: CKRecord) {
            guard let context = self.context else { return }

            let request: NSFetchRequest<Challenge> = Challenge.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", cloudKitRecord.recordID.recordName)
            
            do {
                let results = try context.fetch(request)
                let challenge: Challenge
                
                if results.isEmpty {
                    // Create new Challenge
                    challenge = Challenge(context: context)
                    challenge.id = cloudKitRecord.recordID.recordName // Assuming 'id' is a String attribute in your Challenge entity
                } else {
                    // Update existing Challenge
                    challenge = results.first!
                }
                
                // Assuming 'goalSteps' and 'active' are attributes in your Challenge entity
                challenge.goalSteps = cloudKitRecord["goalSteps"] as? Int32 ?? 0
                challenge.active = cloudKitRecord["active"] as? Bool ?? true
                
                // Assuming 'startTime' and 'endTime' are Date attributes in your Challenge entity
                challenge.startTime = cloudKitRecord["startTime"] as? Date
                challenge.endTime = cloudKitRecord["endTime"] as? Date
                
                // Update participants if needed
                if let participantReferences = cloudKitRecord["participants"] as? [CKRecord.Reference] {
                    updateChallengeParticipants(challenge: challenge, participantReferences: participantReferences)
                }
                
                saveContext()
            } catch {
                print("Failed to fetch or create challenge: \(error)")
            }
        }
        
    private func updateChallengeParticipants(challenge: Challenge, participantReferences: [CKRecord.Reference]) {
        guard let context = challenge.managedObjectContext else { return }
        
        // Convert CKRecord.Reference to String IDs for fetching
        let participantIDs = participantReferences.map { $0.recordID.recordName }
        
        // Fetch all Users that match the participant references
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "recordID IN %@", participantIDs)
        
        do {
            let existingParticipants = try context.fetch(fetchRequest)
            
            // Create a dictionary for quick lookup
            let participantsDict = Dictionary(uniqueKeysWithValues: existingParticipants.map { ($0.appleId!, $0) })
            
            // Prepare a set to store the final set of participants
            var updatedParticipants = Set<User>()
            
            for participantID in participantIDs {
                if let user = participantsDict[participantID] {
                    // Existing user, add to the challenge
                    updatedParticipants.insert(user)
                } else {
                    // No existing user found, create a new one
                    let newUser = User(context: context)
                    newUser.appleId = participantID // Assuming 'recordID' is the property to match CKRecord.ID
                    // Configure newUser as needed
                    
                    updatedParticipants.insert(newUser)
                }
            }
            
            // Update the challenge's participants
            challenge.users = NSSet(set: updatedParticipants)
            
            // Save the context if needed
            try context.save()
        } catch {
            print("Error updating challenge participants: \(error)")
        }
    }

    
    func syncChallenge(with cloudKitRecord: CKRecord) {
           guard let context = self.context else { return }
           
           let request: NSFetchRequest<Challenge> = Challenge.fetchRequest()
           request.predicate = NSPredicate(format: "id == %@", cloudKitRecord.recordID.recordName)
           
           context.perform {
               do {
                   let matches = try context.fetch(request)
                   let challenge: Challenge
                   
                   if let existingChallenge = matches.first {
                       challenge = existingChallenge
                   } else {
                       // Create a new Challenge if it doesn't exist
                       challenge = Challenge(context: context)
                       challenge.id = cloudKitRecord.recordID.recordName // Set 'id' only upon creation
                   }
                   
                   // Update challenge properties but do not attempt to modify 'id' here
                   challenge.goalSteps = cloudKitRecord["goalSteps"] as? Int32 ?? 0
                   challenge.active = cloudKitRecord["active"] as? Bool ?? true
                   // Set other fields as necessary...
                   
                   try context.save()
               } catch {
                   print("Error syncing challenge: \(error)")
               }
           }
       }
    
    // Update or create a daily log for today with new step and calorie data
       func updateDailyLog(with steps: Int, calories: Int, date: Date = Date()) {
           guard let context = self.context else { return }
           
           // Fetch the current user or create one if it doesn't exist
           let user = fetchOrCreateUserSettings()
           
           // Check if a daily log exists for today, otherwise create a new one
           let dailyLog = user.dailyLog(for: date) ?? DailyLog(context: context)
           
           // Update the log details
           dailyLog.totalSteps = Int32(steps)
           dailyLog.caloriesBurned = Int32(calories)
           dailyLog.date = date
           
           // If the log is new, add it to the user's daily logs
           if dailyLog.isInserted {
               user.addToDailyLogs(dailyLog)
           }
           
           // Save changes
           saveContext()
       }
    
    func updateUserLifetimeSteps(additionalSteps: Int) {
        let user = fetchOrCreateUserSettings()

        // Update the lifetime steps with the additional steps
        let newLifetimeSteps = Int(user.lifetimeSteps) + additionalSteps
        user.lifetimeSteps = Int32(newLifetimeSteps)
        
        // Save the context to persist changes
        saveContext {
            // You can use a completion block if needed, for example, to update UI or log success.
            print("Updated user lifetime steps successfully.")
        }
    }

    func checkAndUpdatePersonalBest(with steps: Int, calories: Int) {
        let user = fetchOrCreateUserSettings()

        var isRecordUpdated = false

        // Check if today's steps are a new record
        if steps > user.stepsRecord {
            user.stepsRecord = Int32(steps)
            isRecordUpdated = true
        }

        // Check if today's calories are a new record
        if calories > user.calorieRecord {
            user.calorieRecord = Int32(calories)
            isRecordUpdated = true
        }

        // Save the context if a new record is set
        if isRecordUpdated {
            saveContext {
                // Again, a completion block can be used here if needed.
                print("Updated personal best record successfully.")
            }
        }
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
    
    
    func saveContext(completion: @escaping () -> Void = {}) {
        if ((context?.hasChanges) != nil) {
            do {
                try context?.save()
                completion() // Call completion handler after save is successful
            } catch {
                print("Error saving context: \(error)")
                completion() // Call completion handler even if save fails
            }
        } else {
            completion() // Call completion handler if there's nothing to save
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
