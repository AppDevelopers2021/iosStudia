import SwiftUI
import Firebase
import GoogleSignIn
import CryptoKit
import AuthenticationServices

struct Note: Identifiable {
    var id = UUID()
    var idx: Int
    var subject: String
    var content: String
}

struct CalendarView: View {
    @State private var selectedDate: Date = Date()  // Date selected from date picker
    @State private var isPickerOpen: Bool = false   // Used to show & hide date picker
    @State private var memo = ""                    // Memo value to display
    @State private var reminders = ""               // Reminders to display
    @State private var reminderArray: NSArray = []  // Array of reminders (to pass to ReminderDetailsView
    @State private var notes: [Note] = []           // Notes to display
    @State private var showAddNoteModal = false     // Show "Add Note" Modal
    @State private var showAccountModal = false     // Show Account Modal
    @State private var loggedOut: Bool = false      // Navigate to LoginView When User Signs Out
    
    // Format date to display on screen
    let formatDisplay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY / MM / dd"
        return formatter
    }()
    // Format date for Firebase DB
    let formatForDB: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYYMMdd"
        return formatter
    }()
    
    func load() {
        // Take a snapshot of the DB and parse it
        guard let uid = Auth.auth().currentUser?.uid else { return }    // User UID (Unique ID)
        Database.database().reference().child("calendar/\(uid)/\(formatForDB.string(from: selectedDate))").observe(DataEventType.value, with: { snapshot in
            if let fetchedData = snapshot.value as? NSDictionary {
                // Parse notes
                if let fetchedNotes = fetchedData["note"] as? NSArray {
                    // Store notes from DB as Note identifiable
                    var noteList: [Note] = []
                    for i in 0..<fetchedNotes.count {
                        if let currentNote = fetchedNotes[i] as? NSDictionary {
                            noteList.append(Note(idx: i, subject: currentNote["subject"] as! String, content: currentNote["content"] as! String))
                        } else { self.notes = [] }
                    }
                    self.notes = noteList
                } else { self.notes = [] }      // Content doesn't exsist
                
                // Parse & show memo
                if let fetchedMemo = fetchedData["memo"] as? String {
                    self.memo = fetchedMemo
                } else { self.memo = "" }       // Content doesn't exsist
                
                // Parse & show reminders
                if let fetchedReminderArray = fetchedData["reminder"] as? NSArray {
                    self.reminderArray = fetchedReminderArray
                    self.reminders = " ??? " + fetchedReminderArray.map({"\($0)"}).joined(separator: "\n ??? ")
                } else { self.reminders = "" }  // Content doesn't exsist
            } else {
                // Content doesn't exsist
                self.notes = []
                self.memo = ""
                self.reminders = ""
            }
        });
    }
    
    var body: some View {
            ZStack {
                Color("ThemeColor")
                    .edgesIgnoringSafeArea(.top)
                Color("BgColor")
                GeometryReader { geometry in
                    ScrollView {
                        VStack(spacing: 15) {
                            NavigationLink(destination: LoginView().accentColor(.blue), isActive: $loggedOut) { EmptyView() }
                            
                            HStack {
                                // Date navigation
                                Button(action: {
                                    // Date - 1day
                                    selectedDate -= 86400
                                    load()
                                }) {
                                    Image(systemName: "chevron.left")
                                        .foregroundColor(Color("TextColor"))
                                        .font(.system(size: 25))
                                        .padding(.trailing, 10)
                                }
                                Button(action: {
                                    // Open & close the date picker
                                    withAnimation(Animation.easeInOut(duration: 0.3)) {
                                        isPickerOpen.toggle()
                                    }
                                }) {
                                    Text(formatDisplay.string(from: selectedDate))
                                        .foregroundColor(Color("TextColor"))
                                        .font(.system(size: 25))
                                }
                                Button(action: {
                                    // Date + 1day
                                    selectedDate += 86400
                                    load()
                                }) {
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color("TextColor"))
                                        .font(.system(size: 25))
                                        .padding(.leading, 10)
                                }
                                Spacer()
                                
                                // Add Note button
                                Button(action: {
                                    self.showAddNoteModal = true
                                }) {
                                    Image(systemName: "plus.circle")
                                        .foregroundColor(Color("TextColor"))
                                        .font(.system(size: 25))
                                        .padding(.trailing, 10)
                                }
                                .sheet(isPresented: self.$showAddNoteModal) {
                                    AddNoteModalView(idx: notes.count, date: formatForDB.string(from: selectedDate))
                                }
                            }
                            
                            if isPickerOpen {
                                DatePicker("?????? ??????", selection: $selectedDate, displayedComponents: .date)
                                    .datePickerStyle(WheelDatePickerStyle())
                                    .labelsHidden()
                                    .onChange(of: selectedDate, perform: { _newValue in
                                        // User changes the picker value
                                        load()
                                    })
                            }
                            
                            VStack {
                                ForEach(notes) { note in
                                    NavigationLink(destination: NoteDetailsView(selectedNote: note, date: selectedDate)) {
                                        HStack(alignment: .center, spacing: 10) {
                                            Text(note.subject)
                                                .frame(width: 35, height:35)
                                                .foregroundColor(Color.white)
                                                .background(Color.purple)
                                                .font(.system(size: 15))
                                                .cornerRadius(10)
                                            
                                            Text(note.content)
                                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                                .multilineTextAlignment(.leading)
                                        }
                                        .padding(7)
                                        .foregroundColor(Color("TextColor"))
                                        .background(Color("HighlightBgColor"))
                                        .cornerRadius(10)
                                    }
                                }
                            }
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
                            .background(Color("BgColor"))
                            .padding(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color("ThemeColor"), style: StrokeStyle(lineWidth: 3, dash: [11]))
                            )
                            
                            if geometry.size.width < geometry.size.height {
                                // In portrait mode: show in a row
                                VStack {
                                    NavigationLink(destination: MemoDetailsView(memoContent: memo, date: selectedDate)) {
                                        VStack(alignment: .leading, spacing: 10) {
                                            Text("??????")
                                                .foregroundColor(Color("TextColor"))
                                                .font(.system(size: 25, weight: .semibold))
                                            Text(memo)
                                                .foregroundColor(Color("TextColor"))
                                                .font(.system(size: 20))
                                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 50, alignment: .leading)
                                        }
                                        .padding([.vertical], 15)
                                    }
                                    .padding(10)
                                    .background(Color("HighlightBgColor"))
                                    .cornerRadius(10)
                                    
                                    NavigationLink(destination: ReminderDetailsView(reminderContent: reminderArray, date: selectedDate)) {
                                        VStack(alignment: .leading, spacing: 10) {
                                            Text("?????? ??? ?????????")
                                                .foregroundColor(Color("TextColor"))
                                                .font(.system(size: 25, weight: .semibold))
                                            Text(reminders)
                                                .foregroundColor(Color("TextColor"))
                                                .font(.system(size: 20))
                                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 50, alignment: .leading)
                                                .multilineTextAlignment(.leading)
                                        }
                                        .padding([.vertical], 15)
                                    }
                                    .padding(10)
                                    .background(Color("HighlightBgColor"))
                                    .cornerRadius(10)
                                }
                            } else {
                                // In landscape mode: show horizontally
                                HStack {
                                    NavigationLink(destination: MemoDetailsView(memoContent: memo, date: selectedDate)) {
                                        VStack(alignment: .leading, spacing: 10) {
                                            Text("??????")
                                                .foregroundColor(Color("TextColor"))
                                                .font(.system(size: 25, weight: .semibold))
                                            Text(memo)
                                                .foregroundColor(Color("TextColor"))
                                                .font(.system(size: 20))
                                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 50, alignment: .leading)
                                        }
                                        .padding([.vertical], 15)
                                    }
                                    .padding(10)
                                    .background(Color("HighlightBgColor"))
                                    .cornerRadius(10)
                                    
                                    NavigationLink(destination: ReminderDetailsView(reminderContent: reminderArray, date: selectedDate)) {
                                        VStack(alignment: .leading, spacing: 10) {
                                            Text("?????? ??? ?????????")
                                                .foregroundColor(Color("TextColor"))
                                                .font(.system(size: 25, weight: .semibold))
                                            Text(reminders)
                                                .foregroundColor(Color("TextColor"))
                                                .font(.system(size: 20))
                                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 50, alignment: .leading)
                                                .multilineTextAlignment(.leading)
                                        }
                                        .padding([.vertical], 15)
                                    }
                                    .padding(10)
                                    .background(Color("HighlightBgColor"))
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .padding()
                        .background(Color("BgColor"))
                        .navigationTitle("??? ?????????")
                        .navigationBarBackButtonHidden(true)
                        .toolbar {
                            // Settings icon
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button(action: {
                                    self.showAccountModal = true
                                }) {
                                    Image("cog.fill")
                                        .font(.system(size: 40))
                                }
                                .sheet(isPresented: self.$showAccountModal) {
                                    SettingsModalView(loggedOut: $loggedOut)
                                }
                            }
                        }
                        .onAppear {
                            // Change Navigation Bar background color
                            let navigationBarAppearance = UINavigationBar.appearance()
                            navigationBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
                            navigationBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
                            navigationBarAppearance.backgroundColor = UIColor(Color("ThemeColor"))
                            navigationBarAppearance.barTintColor = UIColor(Color("ThemeColor"))
                            
                            load()
                        }
                    }
                }
            }
    }
}

struct AddNoteModalView: View {
    var idx: Int
    var date: String
    
    @State private var selectedSubject: String = "??????"       // Selected subject
    @State private var selectedOptionalSubject: String = "" // Subject in "Other" mode
    @State private var inputContent: String = ""            // Content input by user
    
    // Full list of all subjects
    let subjects = ["??????", "??????", "??????", "??????", "??????", "??????", "??????", "??????", "??????", "??????", "??????", "??????", "??????", "??????", "??????", "??????", "??????", "??????", "??????"]
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    var body: some View {
        Group {
            NavigationView {
                VStack {
                    Form {
                        Section(header: Text("??????"), content: {
                            Picker("?????? ??????", selection: $selectedSubject) {
                                ForEach(subjects, id: \.self) { option in
                                    Text(option)
                                }
                            }
                            .pickerStyle(.menu)
                            .accentColor(Color("TextColor"))
                            .padding(.trailing, 50)
                            
                            if selectedSubject == "??????" {
                                // User selected "Other"
                                TextField("?????? ??????", text: $selectedOptionalSubject)
                                    .accentColor(.blue)
                            }
                        })
                        
                        Section(header: Text("??????"), content: {
                            TextField("?????? ??????", text: $inputContent)
                                .accentColor(.blue)
                        })
                    }
                }
                .navigationTitle("?????? ??????")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            self.presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("??????")
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            if inputContent != "" {                         // Prevent writing empty string to DB
                                guard let uid = Auth.auth().currentUser?.uid else { return }
                                if selectedSubject == "??????" {               // Use optional subject instead
                                    Database.database().reference().child("calendar/\(uid)/\(date)/note/\(idx)").setValue(["subject": selectedOptionalSubject, "content": inputContent])
                                } else {
                                    Database.database().reference().child("calendar/\(uid)/\(date)/note/\(idx)").setValue(["subject": selectedSubject, "content": inputContent])
                                }
                            }
                            self.presentationMode.wrappedValue.dismiss()    // Close modal
                        }) {
                            Text("??????")
                        }
                    }
                }
            }
            .accentColor(.white)
            .onAppear {
                // Put form bg color back to normal, after user visits NoteDetailsView
                UITableView.appearance().backgroundColor = UIColor.systemGroupedBackground
            }
        }
    }
}

struct SettingsModalView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.openURL) var openURL
    @AppStorage("persistence") var persistence: Bool = UserDefaults.standard.bool(forKey: "persistence")    // User preferences for offline persistence
    @Binding var loggedOut: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    NavigationLink(destination: AccountModalView(loggedOut: $loggedOut, settingsModal: presentationMode)) {
                        HStack(spacing: 15) {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .foregroundColor(Color("FormHighlightColor"))
                                .frame(width: 55, height: 55)
                            
                            VStack(alignment: .leading, spacing: 0) {
                                Text("?????? ??????")
                                    .font(.system(size: 18))
                                Text(String(Auth.auth().currentUser?.email ?? "????????? ??????"))
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                        }
                        .padding(5)
                    }
                    
                    Section(header: Text("????????????"), footer: Text("???????????? ????????? ????????? ???????????? ???????????? ??????????????? ????????? ???????????? ???????????????.")) {
                        Toggle(isOn: $persistence) {
                            Text("???????????? ?????????")
                        }
                    }
                    
                    Section(header: Text("??????")) {
                        HStack {
                            Text("??? ??????")
                            Spacer()
                            Text(Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String ?? "Version")
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            Text("????????????")
                            Spacer()
                            Text(Bundle.main.infoDictionary!["CFBundleVersion"] as? String ?? "Build No.")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Section {
                        Button("?????? ??????") {
                            openURL(URL(string: "https://blog.studia.blue/policy/policy/")!)
                        }
                        Button("????????????????????????") {
                            openURL(URL(string: "https://blog.studia.blue/policy/privacy-statement/")!)
                        }
                        Button("????????? ??? ?????????") {
                            openURL(URL(string: "https://studia.blue/")!)
                        }
                    }
                    .accentColor(.blue)
                }
            }
            .navigationTitle("??????")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("??????")
                    }
                }
            }
        }
        .accentColor(.white)
        .onAppear {
            // Put form bg color back to normal, after user visits NoteDetailsView
            UITableView.appearance().backgroundColor = UIColor.systemGroupedBackground
        }
    }
}

struct AccountModalView: View {
    @State private var showingLogOutSheet: Bool = false         // Show "Wanna log out?" action sheet
    @State private var showDeleteAccountModal: Bool = false     // Show reauthentication modal
    @Binding var loggedOut: Bool
    @Binding var settingsModal: PresentationMode
    
    var body: some View {
        VStack {
            Form {
                HStack {
                    Spacer()
                    VStack(alignment: .center) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .foregroundColor(Color("FormHighlightColor"))
                            .frame(width: 90, height: 90)
                        
                        Text("??? ??????")
                            .font(.system(size: 25))
                        Text(String(Auth.auth().currentUser?.email ?? "????????? ??????"))
                            .foregroundColor(.gray)
                            .font(.system(size: 15))
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .listRowInsets(EdgeInsets())
                .background(Color(UIColor.systemGroupedBackground))
                
                Section {
                    NavigationLink(destination: Text(String(Auth.auth().currentUser?.email ?? "????????? ??????"))) {
                        Text("?????????")
                            .foregroundColor(Color("TextColor"))
                    }
                }
                
                Section {
                    Button("????????????", role: .destructive) {
                        self.showingLogOutSheet = true
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
                    .confirmationDialog(
                        "???????????????????????????????",
                        isPresented: $showingLogOutSheet
                    ) {
                        Button("????????????", role: .destructive) {
                            do {
                                try Auth.auth().signOut()
                                self.loggedOut = true
                                settingsModal.dismiss()
                            } catch let signOutError as NSError {
                                print("Error signing out: %@", signOutError)
                            }
                        }
                    }
                    
                    Button("????????????", role: .destructive) {
                        self.showDeleteAccountModal = true
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
                    .sheet(isPresented: self.$showDeleteAccountModal) {
                        DeleteAccountModalView(loggedOut: $loggedOut, settingsModal: $settingsModal)
                    }
                }
            }
        }
        .navigationTitle("?????? ??????")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DeleteAccountModalView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.colorScheme) var colorScheme
    
    @State private var password: String = ""                // Password input
    @State private var showingDeleteSheeet: Bool = false    // Show "Delete account?" action sheet
    @State private var deleteFailed: Bool = false           // Show "Failed" popup
    @State fileprivate var currentNonce: String?            // Nonce value for SIWA
    
    // Move to LoginView when finished
    @Binding var loggedOut: Bool
    @Binding var settingsModal: PresentationMode
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                Text("???????????? ??????\n?????? ?????????\n?????? ??????????????????.")
                    .font(Font.custom("NanumSquare_ac Bold", size: 40))
                    .padding(.bottom, 30)
                
                Text("????????????")
                    .font(.caption)
                    .padding(.leading, 15)
                HStack {
                    SecureField("??? ??? ??? ??? ??? ??? ??? ???", text: $password)
                        .accentColor(.blue)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                        .padding(.leading, 15)
                }
                .frame(height: 40)
                .background(Color("TextFieldBgColor"))
                .cornerRadius(20)
                .padding(.bottom, 10)
                
                Button(action: {
                    let credential: AuthCredential = EmailAuthProvider.credential(withEmail: Auth.auth().currentUser?.email ?? "", password: password)
                    Auth.auth().currentUser?.reauthenticate(with: credential) { result, error in
                        if error == nil {
                            // Reauthenticated
                            self.showingDeleteSheeet = true
                        } else {
                            self.deleteFailed = true
                        }
                    }
                }) {
                    Label("??????????????? ????????????", systemImage: "key.fill")
                        .font(.system(size: 17, weight: .medium))
                        .frame(minWidth: 0, maxWidth: .infinity)
                }
                .frame(height: 45, alignment: .center)
                .background(Color("LoginBtnColor"))
                .foregroundColor(Color.white)
                .cornerRadius(10)
                .confirmationDialog(
                    "?????????????????????????",
                    isPresented: $showingDeleteSheeet
                ) {
                    Button("????????????", role: .destructive) {
                        guard let uid = Auth.auth().currentUser?.uid else { return }
                        Database.database().reference().child("calendar/\(uid)").removeValue()
                        
                        Auth.auth().currentUser?.delete { error in
                            if error == nil {
                                // Account deleted.
                                self.loggedOut = true
                                settingsModal.dismiss()
                            }
                        }
                    }
                }
                
                Button(action: {
                    guard let clientID = FirebaseApp.app()?.options.clientID else { return }
                    let config = GIDConfiguration(clientID: clientID)
                    
                    // Start Signin flow
                    GIDSignIn.sharedInstance.signIn(with: config, presenting: (UIApplication.shared.windows.first?.rootViewController)!) { user, error in
                        if let error = error {
                            print(error.localizedDescription)
                            return
                        }
                        
                        guard
                            let authentication = user?.authentication,
                            let idToken = authentication.idToken
                        else { return }
                        
                        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: authentication.accessToken)
                        
                        Auth.auth().currentUser?.reauthenticate(with: credential) { result, error in
                            if error == nil {
                                // Reauthenticated
                                self.showingDeleteSheeet = true
                            }
                        }
                    }
                }) {
                    Label{
                        Text("Google??? ????????????")
                            .font(.system(size: 17, weight: .medium))
                    } icon: {
                        Image("google_login")
                            .resizable()
                            .frame(width: 17, height: 17)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                }
                .frame(height: 45, alignment: .center)
                .background(Color("BgColor"))
                .cornerRadius(10)
                .foregroundColor(Color("TextColor"))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color("ThemeColor"), lineWidth: 2)
                )
                .padding(.top, 5)
                
                SignInWithAppleButton(.continue, onRequest: AppleIDDeleteAccountConfigure, onCompletion: AppleIDDeleteAccountHandle)
                    .signInWithAppleButtonStyle(
                        colorScheme == .dark ? .white : .black
                    )
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .frame(height: 45, alignment: .center)
                    .cornerRadius(10)
                    .padding(.top, 5)
            }
            .frame(minWidth: 0, maxWidth: 500)
            .padding()
            .navigationTitle("????????????")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("??????")
                    }
                }
            }
            .alert(isPresented: $deleteFailed) {
                Alert(title: Text("?????? ??????"),
                      message: Text("??????????????? ?????????????????????."),
                      dismissButton: .default(Text("??????"))
                )
            }
        }
        .accentColor(.white)
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError(
                        "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
                    )
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    func AppleIDDeleteAccountConfigure(request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.email]
        request.nonce = sha256(nonce)
    }
    
    func AppleIDDeleteAccountHandle(authResult: Result<ASAuthorization, Error>) {
        switch authResult {
        case .success(let auth):
            print(auth)
            if let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential {
                guard let nonce = currentNonce else {
                    fatalError("Invalid state: A login callback was received, but no login request was sent.")
                }
                guard let appleIDToken = appleIDCredential.identityToken else {
                    print("Unable to fetch identity token")
                    return
                }
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                    return
                }
                // Initialize a Firebase credential.
                let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                          idToken: idTokenString,
                                                          rawNonce: nonce)
                
                Auth.auth().currentUser?.reauthenticate(with: credential) { result, error in
                    if error == nil {
                        // Reauthenticated
                        self.showingDeleteSheeet = true
                    }
                }
            } else { print("error!") }
            
        case .failure(let error):
            print(error)
        }
    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
    }
}
