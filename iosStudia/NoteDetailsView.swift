import SwiftUI
import Firebase

struct NoteDetailsView: View {
    @State private var isInEditMode: Bool = false           // Let user edit stuff if true
    @State private var editedSubject: String = ""           // Edited subject to write to DB
    @State private var editedOptionalSubject: String = ""   // Used when user selects "Other"
    @State private var editedContent: String = ""           // Edited content to write to DB
    @State private var showingDeleteSheet: Bool = false     // Show "Delete note?" action sheet
    
    // Full list of all subjects
    let subjects = ["가정", "과학", "국어", "기술", "도덕", "독서", "미술", "보건", "사회", "수학", "영어", "음악", "정보", "진로", "창체", "체육", "환경", "자율", "기타"]
    
    // Variables passed on from CalendarView
    var selectedNote: Note
    var date: Date
    
    // Format date value for DB (YYYYMMDD)
    let formatForDB: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYYMMdd"
        return formatter
    }()
    
    var body: some View {
        ZStack {
            Color("ThemeColor")
                .edgesIgnoringSafeArea(.top)
            Color(UIColor.systemGroupedBackground)
                .edgesIgnoringSafeArea(.bottom)
            VStack {
                Form {
                    if isInEditMode {
                        // Edit Options
                        Section(header: Text("과목"), content: {
                            Picker("과목 선택", selection: $editedSubject) {
                                ForEach(subjects, id: \.self) { option in
                                    Text(option)
                                }
                            }
                            .pickerStyle(.menu)
                            .accentColor(Color("TextColor"))
                            .padding(.trailing, 50)
                            
                            if editedSubject == "기타" {
                                TextField("직접 입력", text: $editedOptionalSubject)
                                    .accentColor(.blue)
                            }
                        })
                        
                        Section(header: Text("내용"), content: {
                            TextField("내용 입력", text: $editedContent)
                                .accentColor(.blue)
                        })
                        
                        Section(header: Text("삭제"), footer: Text("노트를 삭제한 후에는 되돌릴 수 없습니다.")) {
                            Button(role: .destructive, action: {
                                self.showingDeleteSheet = true
                            }) {
                                Text("노트 삭제")
                            }
                            .confirmationDialog(
                                "삭제하시겠습니까?",
                                isPresented: $showingDeleteSheet
                            ) {
                                Button("노트 삭제", role: .destructive) {
                                    guard let uid = Auth.auth().currentUser?.uid else { return }
                                    Database.database().reference().child("calendar/\(uid)/\(formatForDB.string(from: date))").getData(completion: { error, snapshot in
                                        guard error == nil else {
                                            print(error!.localizedDescription)
                                            return;
                                        }
                                        if let fetchedData = snapshot.value as? NSDictionary {
                                            if var fetchedNotes = fetchedData["note"] as? [AnyObject] {
                                                fetchedNotes.remove(at: selectedNote.idx)
                                                Database.database().reference().child("calendar/\(uid)/\(formatForDB.string(from: date))/note").setValue(fetchedNotes)
                                            }
                                        }
                                    });
                                }
                            }
                        }
                    } else {
                        // Show Plain Text
                        Text(selectedNote.subject)
                        Text(selectedNote.content)
                    }
                }
            }
            .navigationTitle("노트")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(isInEditMode)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isInEditMode {
                        Button(action: {
                            withAnimation {
                                isInEditMode = false
                            }
                            
                            editedSubject = selectedNote.subject
                            editedContent = selectedNote.content
                        }) {
                            Text("취소")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isInEditMode  {
                        Button(action: {
                            withAnimation {
                                isInEditMode = false
                            }
                            
                            // Write data to Firebase Realtime DB
                            guard let uid = Auth.auth().currentUser?.uid else { return }
                            Database.database().reference().child("/calendar/\(uid)/\(formatForDB.string(from: date))/note/\(selectedNote.idx)").setValue(["subject": editedSubject, "content": editedContent])
                        }) {
                            Text("완료")
                        }
                    } else {
                        Button(action: {
                            withAnimation {
                                isInEditMode = true
                            }
                        }) {
                            Text("편집")
                        }
                    }
                }
            }
            .onAppear {
                UITableView.appearance().backgroundColor = .clear
                editedSubject = selectedNote.subject
                editedContent = selectedNote.content
            }
        }
    }
}

struct NoteDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        NoteDetailsView(selectedNote: Note(idx: 0, subject: "국어", content: "Test Value for Live Preview"), date: Date())
    }
}
