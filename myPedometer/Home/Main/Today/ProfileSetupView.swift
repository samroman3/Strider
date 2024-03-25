import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject private var userSettingsManager: UserSettingsManager
    @Environment(\.presentationMode) var presentationMode
    @State private var isEditMode = false
    @State private var userName: String = ""
    @State private var profileImage: Image? = nil
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var dailyStepGoal: Int = 10000
    @State private var dailyCalGoal: Int = 500
    @State private var newStepGoal: String = ""
    @State private var newCalGoal: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Information")) {
                    if isEditMode {
                        TextField("User Name", text: $userName)
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
                        }
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
            }
            .navigationBarTitle("Profile", displayMode: .inline)
            .navigationBarItems(trailing: editButton)
            .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
                ImagePicker(image: self.$inputImage)
            }
            .onAppear(perform: loadCurrentValues)
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
    
    
    
    
    func goalInputField(iconName: String, placeholder: String, binding: Binding<String>, isCalorie: Bool = false) -> some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(isCalorie ? .red : .green)
            TextField(placeholder, text: binding)
                .keyboardType(.numberPad)
        }
    }
    
    func loadCurrentValues() {
        userSettingsManager.fetchUserDetailsFromCloud { success, error in
            guard success else {
                print("Failed to fetch user details from CloudKit: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            DispatchQueue.main.async {
                // Assuming UserSettingsManager updates its @Published properties upon successful fetch
                self.userName = self.userSettingsManager.userName
                self.dailyStepGoal = self.userSettingsManager.dailyStepGoal
                self.dailyCalGoal = self.userSettingsManager.dailyCalGoal 
                
                if let photoData = self.userSettingsManager.photoData, let uiImage = UIImage(data: photoData) {
                    self.profileImage = Image(uiImage: uiImage)
                }
            }
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
        guard let stepGoal = Int(newStepGoal), let calGoal = Int(newCalGoal) else {
            print("Error: Step Goal and Cal Goal must be valid integers.")
            return
        }
        userSettingsManager.updateUserDetails(image: inputImage, userName: userName, stepGoal: stepGoal, calGoal: calGoal)
        loadCurrentValues()
    }
}
