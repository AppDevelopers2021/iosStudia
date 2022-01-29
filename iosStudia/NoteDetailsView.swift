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
    
    var selectedNote: Note
    
    var body: some View {
        ZStack {
            Color("ThemeColor")
                .edgesIgnoringSafeArea(.top)
            Color("BgColor")
            VStack {
                TextEditor(text: $editContent)
            }
            .navigationTitle("노트")
            .navigationBarTitleDisplayMode(.inline)
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
                        isInEditMode.toggle()
                    }) {
                        if isInEditMode == true {
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
