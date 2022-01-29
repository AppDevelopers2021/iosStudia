//
//  ContentView.swift
//  iosStudia
//
//  Created by 이종우 on 2022/01/06.
//

import SwiftUI
import Firebase
import GoogleSignIn

struct Note : Identifiable {
    var id = UUID()
    var idx: Int
    var subject: String
    var content: String
}

struct CalendarView: View {
    @State var selectedDate: Date = Date()  // Date selected from date picker
    @State var isPickerOpen: Bool = false   // Used to show & hide date picker
    @State var memo = ""                    // Memo value to display
    @State var reminders = ""               // Reminders to display
    @State var notes: [Note] = []           // Notes to display
    @State private var showModal = false    // Show "Add Note" Modal
    
    var showValue: String = ""
    
    
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
                ScrollView() {
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
                                isPickerOpen.toggle()
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
                                self.showModal = true
                            }) {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(Color("TextColor"))
                                    .font(.system(size: 25))
                                    .padding(.trailing, 10)
                            }
                            .sheet(isPresented: self.$showModal) {
                                
                                AddCalendarModalView(idx: notes.count, date: formatForDB.string(from: selectedDate))
                            }
                        }
                        
                        if isPickerOpen {
                            DatePicker("날짜 선택", selection: $selectedDate, displayedComponents: .date)
                                .datePickerStyle(WheelDatePickerStyle())
                                .labelsHidden()
                                .transition(.scale)
                                .onChange(of: selectedDate, perform: { _newValue in
                                    load()
                                })
                        }
                        
                        VStack {
                            ForEach(notes) { note in
                                NavigationLink(destination: NoteDetailsView(selectedNote: note)) {
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
                        .padding(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color("ThemeColor"), style: StrokeStyle(lineWidth: 3, dash: [11]))
                        )
                        
                        NavigationLink(destination: Text("Memo Edit Page")) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("메모")
                                    .foregroundColor(Color("TextColor"))
                                    .font(.system(size: 25, weight: .semibold))
                                Text(memo)
                                    .foregroundColor(Color("TextColor"))
                                    .font(.system(size: 20))
                                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            }
                            .padding([.vertical], 15)
                        }
                        .padding(10)
                        .background(Color("HighlightBgColor"))
                        .cornerRadius(10)
                        
                        NavigationLink(destination: Text("Reminder Edit Page")) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("과제 및 준비물")
                                    .foregroundColor(Color("TextColor"))
                                    .font(.system(size: 25, weight: .semibold))
                                Text(reminders)
                                    .foregroundColor(Color("TextColor"))
                                    .font(.system(size: 20))
                                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding([.vertical], 15)
                        }
                        .padding(10)
                        .background(Color("HighlightBgColor"))
                        .cornerRadius(10)
                    }
                    .padding()
                    .background(Color("BgColor"))
                    .navigationTitle("내 캘린더")
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
        .accentColor(.white)
    }
}

struct AddCalendarModalView: View {
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

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
    }
}
