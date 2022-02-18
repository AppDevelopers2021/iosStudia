//
//  NoteDetailsView.swift
//  iosStudia
//
//  Created by 이종우 on 2022/01/07.
//

import SwiftUI
import Firebase

struct NoteDetailsView: View {
    @State var isInEditMode: Bool = false
    @State var editedSubject: String = ""
    @State var editedOptionalSubject: String = ""
    @State var editedContent: String = ""
    @State private var showingDeleteSheet: Bool = false
    let subjects = ["가정", "과학", "국어", "기술", "도덕", "독서", "미술", "보건", "사회", "수학", "영어", "음악", "정보", "진로", "창체", "체육", "환경", "자율", "기타"]
    
    var selectedNote: Note
    var date: Date
    
    let formatForDB: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYYMMdd"
        return formatter
    }()
    
    var body: some View {
        ZStack {
            Color("ThemeColor")
                .edgesIgnoringSafeArea(.top)
            Color("BgColor")
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
                            .listRowBackground(Color("HighlightBgColor"))
                        
                        Section(header: Text("내용"), content: {
                            TextField("내용 입력", text: $editedContent)
                                .accentColor(.blue)
                        })
                            .listRowBackground(Color("HighlightBgColor"))
                        
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
                        .listRowBackground(Color("HighlightBgColor"))
                    } else {
                        // Show Plain Text
                        Text(selectedNote.subject)
                            .listRowBackground(Color("HighlightBgColor"))
                        Text(selectedNote.content)
                            .listRowBackground(Color("HighlightBgColor"))
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
        NavigationView {NoteDetailsView(selectedNote: Note(idx: 0, subject: "국어", content: "테스트"), date: Date())}
        .accentColor(.white)
    }
}
