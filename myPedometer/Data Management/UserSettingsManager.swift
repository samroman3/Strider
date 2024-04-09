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

final class UserSettingsManager: ObservableObject {
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
        didSet { updateUbiquitousKeyValueStore(key: "hasCompletedOnboarding", value: hasCompletedOnboarding)}
    }
    
    @Published var iCloudConsentGiven: Bool {
        didSet { updateUbiquitousKeyValueStore(key: "iCloudConsentGiven", value: iCloudConsentGiven) }
    }

    @Published var dailyStepGoal: Int = 0
    
    @Published var dailyCalGoal: Int = 0

    
    init() {
        hasCompletedOnboarding = NSUbiquitousKeyValueStore.default.bool(forKey: "hasCompletedOnboarding")
        iCloudConsentGiven = NSUbiquitousKeyValueStore.default.bool(forKey: "iCloudConsentGiven")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: Key Value iCloud Markers
    
   func reloadKeyValueStoreSettings() {
            DispatchQueue.main.async {
                self.hasCompletedOnboarding = NSUbiquitousKeyValueStore.default.bool(forKey: "hasCompletedOnboarding")
                self.iCloudConsentGiven = NSUbiquitousKeyValueStore.default.bool(forKey: "iCloudConsentGiven")
            }
        }
    
    private func updateUbiquitousKeyValueStore<T>(key: String, value: T) {
        NSUbiquitousKeyValueStore.default.set(value, forKey: key)
    }
    
    // MARK: Apple Sign In
    
    private func checkAppleIDCredentialState(userID: String, completion: @escaping (Bool) -> Void) {
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
    
    func updateUserDetails(image: UIImage?, userName: String, stepGoal: Int?, calGoal: Int?, updateImage: Bool = true) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.userName = userName
            // Only update photoData if updateImage flag is true and a new image is provided
            if updateImage, let newImage = image {
                let compressedImageData = compressImage(newImage, targetKB: 200) 
                self.photoData = compressedImageData
            }
            // Proceed to update step goal and calorie goal only if new values are provided
            if let stepGoal = stepGoal {
                self.dailyStepGoal = stepGoal
            }
            if let calGoal = calGoal {
                self.dailyCalGoal = calGoal
            }
            
            // Make sure to only upload imageData if there's a new image
            let imageData = updateImage ? image?.jpegData(compressionQuality: 1.0) : nil
            self.updateProfileCoreDataCache(userName: userName, photoData: imageData, stepGoal: stepGoal ?? self.dailyStepGoal, calGoal: calGoal ?? self.dailyCalGoal)
            self.saveUserUpdatesToCloud(userName: userName, imageData: imageData, stepGoal: stepGoal ?? self.dailyStepGoal, calGoal: calGoal ?? self.dailyCalGoal) { success, error in
                if success {
                    print("Successfully updated user details in CloudKit.")
                } else {
                    print("Failed to update user details in CloudKit: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }

    
    func updateProfileCoreDataCache(userName: String, photoData: Data?, stepGoal: Int, calGoal: Int) {
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
    private func compressImage(_ originalImage: UIImage, targetKB: Int, maximumCompression: CGFloat = 0.1) -> Data? {
        // First, estimate the compression quality to reduce dimensions if necessary
        let maxSizeBytes = targetKB * 1024
        var compressionQuality: CGFloat = 1.0
        var imageData = originalImage.jpegData(compressionQuality: compressionQuality)
        
        // Check if image needs resizing
        if let data = imageData, data.count > maxSizeBytes {
            // Calculate resize factor
            let resizeFactor = sqrt(CGFloat(maxSizeBytes) / CGFloat(data.count))
            if let resizedImage = resizeImage(originalImage, factor: resizeFactor) {
                imageData = resizedImage.jpegData(compressionQuality: compressionQuality)
            }
        }
        
        // Apply further compression if necessary
        while let data = imageData, data.count > maxSizeBytes && compressionQuality > maximumCompression {
            compressionQuality -= 0.05 // Decrease compression in small steps
            imageData = originalImage.jpegData(compressionQuality: compressionQuality)
        }
        
        return imageData
    }

    private func resizeImage(_ image: UIImage, factor: CGFloat) -> UIImage? {
        let newSize = CGSize(width: image.size.width * factor, height: image.size.height * factor)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
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
                self.updateProfileCoreDataCache(userName: self.userName, photoData: self.photoData, stepGoal: self.dailyStepGoal, calGoal: self.dailyCalGoal)
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
//        checkAndUpdatePersonalBest(with: steps, calories: calories)
        // Save changes
        saveContext()
    }
    
    func checkAndUpdatePersonalBest(with steps: Int, calories: Int) {
        let user = fetchOrCreateUserSettings()
    
        // Check if today's steps are a new record
        if steps > user.stepsRecord {
            user.stepsRecord = Int32(steps)
        }
        
        // Check if today's calories are a new record
        if calories > user.calorieRecord {
            user.calorieRecord = Int32(calories)
        }
        
        // Update the lifetime steps with the additional steps
        let newLifetimeSteps = Int(user.lifetimeSteps) + steps
        user.lifetimeSteps = Int32(newLifetimeSteps)
        
        savePersonalBestsToCloud(lifetimeSteps: Int(user.lifetimeSteps), stepsRecord: Int(user.stepsRecord), caloriesRecord: Int(user.calorieRecord)) { saved, error in
            switch saved {
            case true:
                print("saved personalbest/lifetime steps succesfully")
            case false:
                print("error saving personal best/lifetime steps")
            }
        }

    }
    
    func savePersonalBestsToCloud(lifetimeSteps: Int, stepsRecord: Int?, caloriesRecord: Int?, completion: @escaping (Bool, Error?) -> Void) {
        getCurrentUserRecordID { [weak self] result in
            switch result {
            case .success(let recordID):
                guard let self = self else { return }
                self.userRecord = self.user?.toCKRecord(recordID: recordID.recordName)
                self.user?.recordId = recordID.recordName
                let publicDatabase = CKContainer.default().publicCloudDatabase
                publicDatabase.fetch(withRecordID: recordID) { (record, error) in
                    guard let record = record else {
                        completion(false, error)
                        return
                    }

                    // Update the specific fields for lifetime steps and personal bests
                    record["lifetimeSteps"] = lifetimeSteps
                    record["stepsRecord"] = stepsRecord
                    record["caloriesRecord"] = caloriesRecord

                    // Save the record
                    publicDatabase.save(record) { _, error in
                        if let error = error {
                            completion(false, error)
                        } else {
                            completion(true, nil)
                        }
                    }
                }
            case .failure(let error):
                completion(false, error)
            }
        }
    }

}

// Helper extension to convert NSData to UIImage
extension NSData {
    var uiImage: UIImage? { UIImage(data: self as Data) }
}
