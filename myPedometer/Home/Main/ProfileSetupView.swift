import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject private var userSettingsManager: UserSettingsManager
    @Environment(\.presentationMode) var presentationMode
    @State private var isEditMode = false
    @State private var userName: String = ""
    @State private var profileImage: Image? = nil
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var dailyStepGoal: Int = UserDefaultsHandler.shared.retrieveDailyStepGoal() ?? 10000
    @State private var dailyCalGoal: Int = UserDefaultsHandler.shared.retrieveDailyCalGoal() ?? 2000
    @State private var newStepGoal: String = ""
    @State private var newCalGoal: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Information")) {
                    if isEditMode {
                        TextField("User Name", text: $userName)
                        Button("Select a profile picture") {
                            showingImagePicker = true
                        }
                    } else {
                        HStack {
                            if let profileImage = profileImage {
                                profileImage
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.crop.circle.fill.badge.plus")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.gray)
                            }
                            Text(userName.isEmpty ? "User Name" : userName)
                                .font(.headline)
                        }
                    }
                }
                
                Section(header: Text("Daily Goals")) {
                    if isEditMode {
                        goalInputField(iconName: "shoe", placeholder: "Step Goal", binding: $newStepGoal)
                        goalInputField(iconName: "flame", placeholder: "Calorie Goal", binding: $newCalGoal, isCalorie: true)
                        Button("Auto Calculate Calorie Goal", action: autoCalculateCalorieGoal)
                                                   .foregroundColor(.blue)
                    } else {
                        HStack {
                            Image(systemName: "shoe")
                                .foregroundColor(.green)
                            Text("Steps: \(dailyStepGoal)")
                        }
                        HStack {
                            Image(systemName: "flame")
                                .foregroundColor(.red)
                            Text("Calories: \(dailyCalGoal)")
                        }
                    }
                }
                
                if isEditMode {
                    Button("Confirm Changes") {
                        saveProfileAndGoals()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationBarTitle("Profile", displayMode: .inline)
            .navigationBarItems(trailing: Button(isEditMode ? "Done" : "Edit") {
                isEditMode.toggle()
                if !isEditMode {
                    // Load existing values to edit fields when entering edit mode
                    newStepGoal = String(dailyStepGoal)
                    newCalGoal = String(dailyCalGoal)
                }
            })
            .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
                ImagePicker(image: self.$inputImage)
            }
            .onAppear(perform: loadCurrentValues)
        }
    }
    
    func goalInputField(iconName: String, placeholder: String, binding: Binding<String>, isCalorie: Bool = false) -> some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(isCalorie ? .red : .green)
            TextField(placeholder, text: binding)
                .keyboardType(.numberPad)
        }
    }
    
    func loadCurrentValues() {
           self.userName = userSettingsManager.userName
           self.newStepGoal = "\(dailyStepGoal)"
           self.newCalGoal = "\(dailyCalGoal)"
        
           if let photoData = userSettingsManager.photoData, let uiImage = UIImage(data: photoData) {
               self.profileImage = Image(uiImage: uiImage)
           }
       }
    
    func autoCalculateCalorieGoal() {
           guard let stepGoal = Int(newStepGoal) else { return }
           let calculatedCalGoal = Int(Double(stepGoal) * 0.04)
           newCalGoal = String(calculatedCalGoal)
       }
    
    func loadImage() {
        guard let inputImage = inputImage else { return }
        profileImage = Image(uiImage: inputImage)
    }
    
    func saveProfileAndGoals() {
        // Prepare the data for saving
        if let inputImage = inputImage {
            userSettingsManager.uploadProfileImage(inputImage)
        }
        if let stepGoal = Int(newStepGoal), let calGoal = Int(newCalGoal) {
            dailyStepGoal = stepGoal
            dailyCalGoal = calGoal
            UserDefaultsHandler.shared.storeDailyStepGoal(stepGoal)
            UserDefaultsHandler.shared.storeDailyCalGoal(calGoal)
        }
        
        // Save the context
        userSettingsManager.saveContext {
            // This closure is called after the context has been saved
            DispatchQueue.main.async {
                // Dismiss the ProfileSetupView only after saving is complete
                self.presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
