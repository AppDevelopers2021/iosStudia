//
//  NoteDetailsView.swift
//  iosStudia
//
//  Created by 이종우 on 2022/01/07.
//

import SwiftUI

struct NoteDetailsView: View {
    @State var isInEditMode: Bool = false
    @State var editSubject: String = ""
    @State var editContent: String = ""
    let subjects = ["가정", "과학", "국어", "기술", "도덕", "독서", "미술", "보건", "사회", "수학", "영어", "음악", "정보", "진로", "창체", "체육", "환경", "자율", "기타"]
    
    var selectedNote: Note
    
    var body: some View {
        ZStack {
            Color("ThemeColor")
                .edgesIgnoringSafeArea(.top)
            Color("BgColor")
            VStack {
                if isInEditMode {
                    // Edit Options
                    Picker("과목 선택", selection: $editSubject) {
                        ForEach(subjects, id: \.self) { option in
                            Text(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .accentColor(.black)
                    TextField("", text: $editContent)
                } else {
                    // Show Plain Text
                    Text(selectedNote.content)
                }
            }
            .navigationTitle("노트")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(isInEditMode)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isInEditMode {
                        Button(action: {
                            isInEditMode = false
                        }) {
                            Text("취소")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation {
                            isInEditMode.toggle()
                        }
                    }) {
                        if isInEditMode {
                            Text("완료")
                        } else {
                            Text("수정")
                        }
                    }
                }
            }
            .onAppear {
                let navigationBarAppearance = UINavigationBar.appearance()
                navigationBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
                navigationBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
                navigationBarAppearance.backgroundColor = UIColor(Color("ThemeColor"))
            }
        }
    }
}

struct NoteDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {NoteDetailsView(selectedNote: Note(idx: 0, subject: "국어", content: "테스트"))}
        .accentColor(.white)
    }
}
