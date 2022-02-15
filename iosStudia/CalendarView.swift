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
    @State private var isOffline = false        // Show offline indicator
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
        // Detect if connection is offline
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if snapshot.value as? Bool ?? true {
                // Connected
                self.isOffline = false
            } else {
                // Offline
                self.isOffline = true
            }
        })
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Database.database().reference().child("calendar/\(uid)/\(formatForDB.string(from: selectedDate))").observe(DataEventType.value, with: { snapshot in
            if let fetchedData = snapshot.value as? NSDictionary {
                // Show notes
                if let fetchedNotes = fetchedData["note"] as? NSArray {
                    var noteList: [Note] = []
                    for i in 0..<fetchedNotes.count {
                        let currentNote = fetchedNotes[i] as! NSDictionary
                        noteList.append(Note(idx: i, subject: currentNote["subject"] as! String, content: currentNote["content"] as! String))
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
                        if isOffline {
                            HStack {
                                // Offline Warning Message
                                Spacer()
                                Image(systemName: "wifi.slash")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.white)
                                Text("오프라인 상태입니다.")
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(10)
                            .background(.red)
                            .cornerRadius(10)
                            .padding(EdgeInsets(top: 15, leading: 15, bottom: 0, trailing: 15))
                        }
                        
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
                            .accentColor(.black)
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
                            guard let uid = Auth.auth().currentUser?.uid else { return }
                            if selectedSubject == "기타" {
                                Database.database().reference().child("calendar/\(uid)/\(date)/note/\(idx)").setValue(["subject": selectedOptionalSubject, "content": inputContent])
                            } else {
                                Database.database().reference().child("calendar/\(uid)/\(date)/note/\(idx)").setValue(["subject": selectedSubject, "content": inputContent])
                            }
                            self.presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("완료")
                        }
                    }
                }
            }
            .accentColor(.white)
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
    }
}

struct AccountModalView: View {
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
                    NavigationLink(destination: Text("hi")) {
                        Text("이메일")
                            .foregroundColor(Color("TextColor"))
                    }
                    
                    NavigationLink(destination: Text("hi")) {
                        Text("암호 및 보안")
                            .foregroundColor(Color("TextColor"))
                    }
                }
                
                Section {
                    Button("로그아웃", role: .destructive) {
                        do {
                            try Auth.auth().signOut()
                        } catch let signOutError as NSError {
                            print("Error signing out: %@", signOutError)
                        }
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
                }
            }
        }
        .navigationTitle("계정 관리")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ReAuthModalView: View {
    var body: some View {
        VStack {
            // Reauthenticate
        }
    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
        AccountModalView()
        //.preferredColorScheme(.dark)
    }
}
