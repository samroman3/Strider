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
    var user: User?
    
    @Published var photoData: Data?
    @Published var lifetimeSteps: Int = 0
    @Published var stepsRecord: Int = 0
    @Published var calorieRecord: Int = 0
    @Published var userName: String = ""
    @Published var userRecord: CKRecord?
    @Published var hasSignedInWithApple: Bool = false
    @Published var cloudKitRecordName: String = ""
    
    
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: Key Value iCloud Markers
    
    private func updateUserDefaults<T>(key: String, value: T) {
        UserDefaults.standard.set(value, forKey: key)
    }
    
    private func updateUbiquitousKeyValueStore<T>(key: String, value: T) {
        NSUbiquitousKeyValueStore.default.set(value, forKey: key)
        NSUbiquitousKeyValueStore.default.synchronize()
    }
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
    
    // MARK: Apple Sign In
    
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
            self.setUserCloudKitRecord()
            self.saveContext()
        }
    }
    
    func setUserCloudKitRecord(){
        self.getCurrentUserRecordID { [weak self] result in
            switch result {
            case .success(let recordID):
                // Use the fetched recordID to create or update a User CKRecord
                // This helps ensure that the User CKRecord is associated with the correct iCloud user when managing challenges
                self?.userRecord = self?.user?.toCKRecord(recordID: recordID.recordName)
                self?.user?.recordId = recordID.recordName
                
            case .failure(let error):
                // Handle error
                print("Error fetching current user's CloudKit record ID: \(error.localizedDescription)")
            }
        }
    }
    
    func saveAppleSignInFlag() {
        NSUbiquitousKeyValueStore.default.set(hasSignedInWithApple, forKey: "hasSignedInWithApple")
        NSUbiquitousKeyValueStore.default.synchronize()
    }
    
    
    //MARK: CloudKit Sync
    func checkiCloudAvailability(completion: @escaping (Bool) -> Void) {
        CKContainer.default().accountStatus { accountStatus, error in
            DispatchQueue.main.async {
                if let error = error {
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
    
    func saveUserUpdatesToCloud(userName: String, imageData: Data?, stepGoal: Int, calGoal: Int, completion: @escaping (Bool, Error?) -> Void) {
        getCurrentUserRecordID { [weak self] result in
            switch result {
            case .success(let recordID):
                self?.userRecord = self?.user?.toCKRecord(recordID: recordID.recordName)
                self?.user?.recordId = recordID.recordName
                let publicDatabase = CKContainer.default().publicCloudDatabase
                let recordID = CKRecord.ID(recordName: recordID.recordName)
                publicDatabase.fetch(withRecordID: recordID) { (record, error) in
                    guard let record = record else {
                        completion(false, error)
                        return
                    }
                    
                    // Update fields
                    record["userName"] = userName
                    record["stepGoal"] = stepGoal
                    record["calGoal"] = calGoal
                    
                    // Handle image data if present
                    if let imageData = imageData, let temporaryURL = self?.writeImageDataToFile(imageData) {
                        let imageAsset = CKAsset(fileURL: temporaryURL)
                        record["photo"] = imageAsset
                        
                        // Perform the save operation
                        publicDatabase.save(record) { _, error in
                            if let error = error {
                                completion(false, error)
                                // Clean up temporary file
                                try? FileManager.default.removeItem(at: temporaryURL)
                            } else {
                                completion(true, nil)
                                // Clean up temporary file
                                try? FileManager.default.removeItem(at: temporaryURL)
                            }
                        }
                    } else {
                        // No image data, just save the other updates
                        publicDatabase.save(record) { _, error in
                            if let error = error {
                                completion(false, error)
                            } else {
                                completion(true, nil)
                            }
                        }
                    }
                }
            case .failure(let error):
                completion(false, error)
            }
        }
    }
    
    //MARK: Core Data Sync
    
    func updateUserDetails(image: UIImage?, userName: String, stepGoal: Int?, calGoal: Int?) {
        DispatchQueue.main.async {
            let user = self.fetchOrCreateUserSettings()
            
            if let image = image {
                let imageData = image.jpegData(compressionQuality: 1.0)
                user.photoData = imageData
                self.photoData = imageData
            }
            
            user.userName = userName
            self.userName = userName
            
            if let stepGoal = stepGoal {
                user.stepGoal = Int32(stepGoal)
                self.dailyStepGoal = stepGoal
            }
            
            if let calGoal = calGoal {
                user.calGoal = Int32(calGoal)
                self.dailyCalGoal = calGoal
            }
            
            self.saveContext()
            // Now, update CloudKit with the latest information
            let imageData = image?.jpegData(compressionQuality: 1.0)
            self.saveUserUpdatesToCloud(userName: userName, imageData: imageData, stepGoal: stepGoal ?? self.dailyStepGoal, calGoal: calGoal ?? self.dailyCalGoal) { success, error in
                if success {
                    print("Successfully updated user details in CloudKit.")
                } else {
                    print("Failed to update user details in CloudKit: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    func updateCoreDataCacheWithCloudKitData(userName: String, photoData: Data?, stepGoal: Int, calGoal: Int) {
        DispatchQueue.main.async {
            // Fetch or create the User entity instance
            let user = self.fetchOrCreateUserSettings()
            
            // Update the User entity with the new data
            user.userName = userName
            if let photoData = photoData {
                user.photoData = photoData
            }
            user.stepGoal = Int32(stepGoal)
            user.calGoal = Int32(calGoal)
            
            // Save the updated context
            self.saveContext()
        }
    }

    
    func writeImageDataToFile(_ imageData: Data) -> URL? {
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString + ".jpg"
        let fileURL = temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try imageData.write(to: fileURL)
            return fileURL
        } catch {
            print("Error writing image data to file: \(error)")
            return nil
        }
    }
    func saveContext() {
        guard let context = self.context, context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    func loadUserSettings() {
        user = fetchOrCreateUserSettings()
        if let user = user {
            // Update UI directly since this runs in main thread context already
            self.photoData = user.photoData
            self.lifetimeSteps = Int(user.lifetimeSteps)
            self.stepsRecord = Int(user.stepsRecord)
            self.dailyCalGoal = Int(user.calGoal)
            self.dailyStepGoal = Int(user.stepGoal)
            self.calorieRecord = Int(user.calorieRecord)
            self.userName = user.userName ?? ""
        }
        
        // After populating from cache, fetch updates from CloudKit
        fetchUserDetailsFromCloud { success, error in
            if success {
                print("CloudKit data fetched successfully.")
                self.updateCoreDataCacheWithCloudKitData(userName: self.userName, photoData: self.photoData, stepGoal: self.dailyStepGoal, calGoal: self.dailyCalGoal)
            } else {
                print("Failed to fetch from CloudKit: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
        
        //Set user recordid
        setUserCloudKitRecord()
    }

    
    func fetchUserDetailsFromCloud(completion: @escaping (Bool, Error?) -> Void) {
        getCurrentUserRecordID { [weak self] result in
            switch result {
            case .success(let recordID):
                let publicDatabase = CKContainer.default().publicCloudDatabase
                publicDatabase.fetch(withRecordID: recordID) { (record, error) in
                    DispatchQueue.main.async {
                        guard let self = self, let record = record, error == nil else {
                            completion(false, error)
                            return
                        }

                        // Assuming 'userName', 'stepGoal', and 'calGoal' are the keys used in your CloudKit record
                        if let userName = record["userName"] as? String {
                            self.userName = userName
                        }

                        if let stepGoal = record["stepGoal"] as? Int {
                            self.dailyStepGoal = stepGoal
                        }

                        if let calGoal = record["calGoal"] as? Int {
                            self.dailyCalGoal = calGoal
                        }

                        if let photoAsset = record["photo"] as? CKAsset, let fileURL = photoAsset.fileURL, let imageData = try? Data(contentsOf: fileURL) {
                            self.photoData = imageData
                        }

                        completion(true, nil)
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(false, error)
                }
            }
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
        saveContext()
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
            saveContext()
        }
    }
}

// Helper extension to convert NSData to UIImage
extension NSData {
    var uiImage: UIImage? { UIImage(data: self as Data) }
}
