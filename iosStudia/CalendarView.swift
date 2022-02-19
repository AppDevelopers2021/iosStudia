//
//  ContentView.swift
//  iosStudia
//
//  Created by 이종우 on 2022/01/06.
//

import SwiftUI
import Firebase
import GoogleSignIn

struct Note: Identifiable {
    var id = UUID()
    var idx: Int
    var subject: String
    var content: String
}

struct CalendarView: View {
    @State var selectedDate: Date = Date()      // Date selected from date picker
    @State var isPickerOpen: Bool = false       // Used to show & hide date picker
    @State var memo = ""                        // Memo value to display
    @State var reminders = ""                   // Reminders to display
    @State var reminderArray: NSArray = []      // Array of reminders (to pass to ReminderDetailsView
    @State var notes: [Note] = []               // Notes to display
    @State private var showAddNoteModal = false // Show "Add Note" Modal
    @State private var showAccountModal = false // Show Account Modal
    @State var isLoggedOut = false
    
    
    let formatDisplay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY / MM / dd"
        return formatter
    }()
    let formatForDB: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYYMMdd"
        return formatter
    }()
    
    func load() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Database.database().reference().child("calendar/\(uid)/\(formatForDB.string(from: selectedDate))").observe(DataEventType.value, with: { snapshot in
            if let fetchedData = snapshot.value as? NSDictionary {
                // Show notes
                if let fetchedNotes = fetchedData["note"] as? NSArray {
                    var noteList: [Note] = []
                    for i in 0..<fetchedNotes.count {
                        if let currentNote = fetchedNotes[i] as? NSDictionary {
                            noteList.append(Note(idx: i, subject: currentNote["subject"] as! String, content: currentNote["content"] as! String))
                        } else { self.notes = [] }
                    }
                    self.notes = noteList
                } else { self.notes = [] }
                
                // Show memo
                if let fetchedMemo = fetchedData["memo"] as? String {
                    self.memo = fetchedMemo
                } else { self.memo = "" }
                
                // Show reminders
                if let fetchedReminderArray = fetchedData["reminder"] as? NSArray {
                    self.reminderArray = fetchedReminderArray
                    self.reminders = " • " + fetchedReminderArray.map({"\($0)"}).joined(separator: "\n • ")
                } else { self.reminders = "" }
            } else {
                self.notes = []
                self.memo = ""
                self.reminders = ""
            }
        });
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("ThemeColor")
                    .edgesIgnoringSafeArea(.top)
                Color("BgColor")
                GeometryReader { geometry in
                    ScrollView {
                        VStack(spacing: 15) {
                            HStack {
                                // Date Navigation
                                Button(action: {
                                    // Date Back
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
                                    // Date Forward
                                    selectedDate += 86400
                                    load()
                                }) {
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color("TextColor"))
                                        .font(.system(size: 25))
                                        .padding(.leading, 10)
                                }
                                Spacer()
                                
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
                                DatePicker("날짜 선택", selection: $selectedDate, displayedComponents: .date)
                                    .datePickerStyle(WheelDatePickerStyle())
                                    .labelsHidden()
                                    .onChange(of: selectedDate, perform: { _newValue in
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
                                VStack {
                                    NavigationLink(destination: MemoDetailsView(memoContent: memo, date: selectedDate)) {
                                        VStack(alignment: .leading, spacing: 10) {
                                            Text("메모")
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
                                            Text("과제 및 준비물")
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
                                HStack {
                                    NavigationLink(destination: MemoDetailsView(memoContent: memo, date: selectedDate)) {
                                        VStack(alignment: .leading, spacing: 10) {
                                            Text("메모")
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
                                            Text("과제 및 준비물")
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
                        .navigationTitle("내 캘린더")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button(action: {
                                    self.showAccountModal = true
                                }) {
                                    Image("cog.fill")
                                        .font(.system(size: 40))
                                }
                                .sheet(isPresented: self.$showAccountModal) {
                                    SettingsModalView()
                                }
                            }
                        }
                        .onAppear {
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
        .navigationViewStyle(StackNavigationViewStyle())
        .accentColor(.white)
    }
}

struct AddNoteModalView: View {
    @State var idx: Int
    @State var date: String
    
    @State private var selectedSubject: String = "국어"
    @State private var selectedOptionalSubject: String = ""
    @State private var inputContent: String = ""
    let subjects = ["가정", "과학", "국어", "기술", "도덕", "독서", "미술", "보건", "사회", "수학", "영어", "음악", "정보", "진로", "창체", "체육", "환경", "자율", "기타"]
    
    @Environment (\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    var body: some View {
        Group {
            NavigationView {
                VStack {
                    Form {
                        Section(header: Text("과목"), content: {
                            Picker("과목 선택", selection: $selectedSubject) {
                                ForEach(subjects, id: \.self) { option in
                                    Text(option)
                                }
                            }
                            .pickerStyle(.menu)
                            .accentColor(Color("TextColor"))
                            .padding(.trailing, 50)
                            
                            if selectedSubject == "기타" {
                                TextField("직접 입력", text: $selectedOptionalSubject)
                                    .accentColor(.blue)
                            }
                        })
                        
                        Section(header: Text("내용"), content: {
                            TextField("내용 입력", text: $inputContent)
                                .accentColor(.blue)
                        })
                    }
                }
                .navigationTitle("노트 추가")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            self.presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("취소")
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            if inputContent != "" {
                                guard let uid = Auth.auth().currentUser?.uid else { return }
                                if selectedSubject == "기타" {
                                    Database.database().reference().child("calendar/\(uid)/\(date)/note/\(idx)").setValue(["subject": selectedOptionalSubject, "content": inputContent])
                                } else {
                                    Database.database().reference().child("calendar/\(uid)/\(date)/note/\(idx)").setValue(["subject": selectedSubject, "content": inputContent])
                                }
                            }
                            self.presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("완료")
                        }
                    }
                }
            }
            .accentColor(.white)
            .onAppear {
                UITableView.appearance().backgroundColor = UIColor.systemGroupedBackground
            }
        }
    }
}

struct SettingsModalView: View {
    @Environment (\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.openURL) var openURL
    @AppStorage("persistence") var persistence: Bool = UserDefaults.standard.bool(forKey: "persistence")
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    NavigationLink(destination: AccountModalView()) {
                        HStack(spacing: 15) {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .foregroundColor(Color("FormHighlightColor"))
                                .frame(width: 55, height: 55)
                            
                            VStack(alignment: .leading, spacing: 0) {
                                Text("계정 관리")
                                    .font(.system(size: 18))
                                Text(String(Auth.auth().currentUser?.email ?? "이메일 주소"))
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                        }
                        .padding(5)
                    }
                    
                    Section(header: Text("네트워크"), footer: Text("데이터의 사본을 기기에 저장하여 오프라인 상태에서도 노트를 불러오고 작성합니다.")) {
                        Toggle(isOn: $persistence) {
                            Text("오프라인 지속성")
                        }
                    }
                    
                    Section(header: Text("정보")) {
                        HStack {
                            Text("앱 버전")
                            Spacer()
                            Text(Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String ?? "Version")
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            Text("빌드번호")
                            Spacer()
                            Text(Bundle.main.infoDictionary!["CFBundleVersion"] as? String ?? "Build No.")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Section {
                        Button("이용 약관") {
                            openURL(URL(string: "https://blog.studia.blue/policy/policy/")!)
                        }
                        Button("개인정보처리방침") {
                            openURL(URL(string: "https://blog.studia.blue/policy/privacy-statement/")!)
                        }
                        Button("개발자 웹 사이트") {
                            openURL(URL(string: "https://studia.blue/")!)
                        }
                    }
                    .accentColor(.blue)
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("완료")
                    }
                }
            }
        }
        .accentColor(.white)
        .onAppear {
            UITableView.appearance().backgroundColor = UIColor.systemGroupedBackground
        }
    }
}

struct AccountModalView: View {
    @State private var showingLogOutSheet: Bool = false
    @State private var showingDeleteSheet: Bool = false
    @State private var showingLoggedOutAlert: Bool = false
    @State private var showDeleteAccountModal: Bool = false
    
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
                        
                        Text("내 계정")
                            .font(.system(size: 25))
                        Text(String(Auth.auth().currentUser?.email ?? "이메일 주소"))
                            .foregroundColor(.gray)
                            .font(.system(size: 15))
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .listRowInsets(EdgeInsets())
                .background(Color(UIColor.systemGroupedBackground))
                
                Section {
                    NavigationLink(destination: Text(String(Auth.auth().currentUser?.email ?? "이메일 주소"))) {
                        Text("이메일")
                            .foregroundColor(Color("TextColor"))
                    }
                }
                
                Section {
                    Button("로그아웃", role: .destructive) {
                        self.showingLogOutSheet = true
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
                    .confirmationDialog(
                        "로그아웃하시겠습니까?",
                        isPresented: $showingLogOutSheet
                    ) {
                        Button("로그아웃", role: .destructive) {
                            do {
                                try Auth.auth().signOut()
                                self.showingLoggedOutAlert = true
                            } catch let signOutError as NSError {
                                print("Error signing out: %@", signOutError)
                            }
                        }
                    }
                    
                    Button("회원탈퇴", role: .destructive) {
                        self.showDeleteAccountModal = true
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
                    .sheet(isPresented: self.$showDeleteAccountModal) {
                        DeleteAccountModalView()
                    }
                }
            }
        }
        .navigationTitle("계정 관리")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showingLoggedOutAlert) {
            Alert(title: Text("앱 재시작 필요"),
                  message: Text("로그아웃되었습니다. 앱을 재시작해주세요."),
                  dismissButton: .default(Text("확인"))
            )
        }
    }
}

struct DeleteAccountModalView: View {
    @Environment (\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @State private var password: String = ""
    @State private var showingRestartAlert: Bool = false
    @State private var showingDeleteSheeet: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                Text("회원탈퇴 전에\n접근 권한을\n다시 인증해주세요.")
                    .font(Font.custom("NanumSquare_ac Bold", size: 40))
                    .padding(.bottom, 30)
                
                Text("비밀번호")
                    .font(.caption)
                    .padding(.leading, 15)
                HStack {
                    SecureField("• • • • • • • •", text: $password)
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
                        if error != nil {
                            // Error
                        } else {
                            // Reauthenticated
                            self.showingDeleteSheeet = true
                        }
                    }
                }) {
                    Text("비밀번호 인증")
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .frame(height: 40, alignment: .center)
                }
                .background(Color("ThemeColor"))
                .foregroundColor(Color.white)
                .cornerRadius(10)
                .confirmationDialog(
                    "탈퇴하시겠습니까?",
                    isPresented: $showingDeleteSheeet
                ) {
                    Button("탈퇴하기", role: .destructive) {
                        guard let uid = Auth.auth().currentUser?.uid else { return }
                        Database.database().reference().child("calendar/\(uid)").removeValue()
                        
                        Auth.auth().currentUser?.delete { error in
                            if error != nil {
                                // An error happened.
                            } else {
                                // Account deleted.
                                self.showingRestartAlert = true
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
                        else {
                            return
                        }
                        
                        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: authentication.accessToken)
                        
                        Auth.auth().currentUser?.reauthenticate(with: credential) { result, error in
                            if error != nil {
                                // Error
                            } else {
                                // Reauthenticated
                                self.showingDeleteSheeet = true
                            }
                        }
                    }
                }) {
                    Image("google_login")
                        .resizable()
                        .frame(width: 25, height: 25)
                    
                    Text("Google 계정으로 인증")
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                .frame(height: 40, alignment: .center)
                .background(Color("BgColor"))
                .cornerRadius(10)
                .foregroundColor(Color("TextColor"))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color("ThemeColor"), lineWidth: 2)
                )
                .padding(.top, 5)
            }
            .frame(minWidth: 0, maxWidth: 500)
            .padding()
            .navigationTitle("회원탈퇴")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("취소")
                    }
                }
            }
            .alert(isPresented: $showingRestartAlert) {
                Alert(title: Text("앱 재시작 필요"),
                      message: Text("탈퇴 절차가 완료되었습니다. 앱을 재시작해주세요."),
                      dismissButton: .default(Text("확인"))
                )
            }
        }
        .accentColor(.white)
    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
        DeleteAccountModalView()
        //.preferredColorScheme(.dark)
    }
}

extension String {
    var localized: String {
        return NSLocalizedString(self, tableName: "Localizable", value: self, comment: "")
    }
}
