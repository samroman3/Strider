import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject private var userSettingsManager: UserSettingsManager
    @State private var isEditMode = false
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var editingUserName: String = ""
    @State private var editingStepGoal: String = ""
    @State private var editingCalGoal: String = ""

    // Convert Data to Image for displaying
    private var profileImage: Image? {
        if let photoData = userSettingsManager.photoData {
            return Image(uiImage: UIImage(data: photoData) ?? UIImage())
        }
        return nil
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Information")) {
                    if isEditMode {
                        TextField("User Name", text: $userSettingsManager.userName)
                        profileImageView
                        Button("Select a profile picture") { showingImagePicker = true }
                    } else {
                        HStack {
                            profileImageView
                            Text(userSettingsManager.userName)
                                .font(.headline)
                        }
                    }
                }
                
                Section(header: Text("Daily Goals")) {
                    if isEditMode {
                        goalInputField(iconName: "shoe", placeholder: "Step Goal", binding: $editingStepGoal)
                        goalInputField(iconName: "flame", placeholder: "Calorie Goal", binding: $editingCalGoal, isCalorie: true)
                        Button("Auto Calculate Calorie Goal", action: autoCalculateCalorieGoal)
                            .foregroundColor(.blue)
                    } else {
                        HStack {
                            Image(systemName: "shoe")
                                .foregroundColor(.green)
                            Text("Steps: \(userSettingsManager.dailyStepGoal)")
                        }
                        HStack {
                            Image(systemName: "flame")
                                .foregroundColor(.red)
                            Text("Calories: \(userSettingsManager.dailyCalGoal)")
                        }
                    }
                }
                
            }
            .onAppear {
                            // Initialize editing values when the view appears
                            self.editingUserName = self.userSettingsManager.userName
                            self.editingStepGoal = "\(self.userSettingsManager.dailyStepGoal)"
                            self.editingCalGoal = "\(self.userSettingsManager.dailyCalGoal)"
                        }
            .navigationBarTitle("Profile", displayMode: .inline)
            .navigationBarItems(trailing: editButton)
            .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
                ImagePicker(image: self.$inputImage)
            }
        }
    }

    private var profileImageView: some View {
        Group {
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
        }
    }

    var editButton: some View {
        Button(action: {
            if isEditMode {
                saveProfileAndGoals()
            }
            isEditMode.toggle()
        }) {
            Text(isEditMode ? "Done" : "Edit")
        }
    }
    
    func loadImage() {
        guard let inputImage = inputImage else { return }
        userSettingsManager.photoData = inputImage.jpegData(compressionQuality: 0.8)
    }
    
    func goalInputField(iconName: String, placeholder: String, binding: Binding<String>, isCalorie: Bool = false) -> some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(isCalorie ? .red : .green)
            TextField(binding.wrappedValue, text: binding)
                .keyboardType(.numberPad)
        }
    }
    
    func autoCalculateCalorieGoal() {
           guard let stepGoal = Int(editingStepGoal) else { return }
           let calculatedCalGoal = Int(Double(stepGoal) * 0.04)
           editingCalGoal = String(calculatedCalGoal)
       }
    
    func saveProfileAndGoals() {
        if let stepGoal = Int(editingStepGoal), let calGoal = Int(editingCalGoal) {
            // Call updateUserDetails without modifying the image if no new image has been selected.
            let updateImage = inputImage != nil
            userSettingsManager.updateUserDetails(image: inputImage, userName: userSettingsManager.userName, stepGoal: stepGoal, calGoal: calGoal, updateImage: updateImage)
        }
    }
}
