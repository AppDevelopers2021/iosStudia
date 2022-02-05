//
//  MemoEditView.swift
//  iosStudia
//
//  Created by 이종우 on 2022/01/07.
//

import SwiftUI
import Firebase

struct MemoDetailsView: View {
    @State var isInEditMode: Bool = false
    @State var edited: String = ""
    
    @FocusState private var fieldIsFocused: Bool
    
    var memoContent: String
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
                if isInEditMode {
                    // Edit
                    TextField("메모 내용 입력", text: $edited)
                        .accentColor(.blue)
                        .focused($fieldIsFocused)
                } else {
                    // Just Text
                    Text(memoContent)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Spacer()
            }
            .padding()
            .navigationTitle("메모")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(isInEditMode)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isInEditMode {
                        Button(action: {
                            withAnimation {
                                isInEditMode = false
                            }
                        }) {
                            Text("취소")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isInEditMode {
                        Button(action: {
                            withAnimation {
                                isInEditMode = false
                            }
                            
                            // Write data to Firebase Realtime DB
                            guard let uid = Auth.auth().currentUser?.uid else { return }
                            Database.database().reference().child("/calendar/\(uid)/\(formatForDB.string(from: date))/memo").setValue(edited)
                        }) {
                            Text("완료")
                        }
                    } else {
                        Button(action: {
                            withAnimation {
                                isInEditMode = true
                                self.edited = memoContent
                                self.fieldIsFocused = true
                            }
                        }) {
                            Text("편집")
                        }
                    }
                }
            }
        }
    }
}

struct MemoDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {MemoDetailsView(memoContent: "Test Memo", date: Date())}
    }
}
