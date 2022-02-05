//
//  ReminderDetailsView.swift
//  iosStudia
//
//  Created by 이종우 on 2022/02/03.
//

import SwiftUI
import Firebase

struct ReminderDetailsView: View {
    @State var isInEditMode: Bool = false
    @State var initialValue: [String] = []
    @State var edited: [String] = []
    
    var reminderContent: NSArray
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
                List {
                    ForEach(Array(edited.indices), id: \.self) { index in
                        TextField("내용 입력", text: Binding(
                            get: { return edited[index] },
                            set: { (newValue) in return self.edited[index] = newValue }
                        ))
                            .disabled(!isInEditMode)
                            .accentColor(.blue)
                    }
                    .onDelete { indexSet in
                        edited.remove(atOffsets: indexSet)
                    }
                    .deleteDisabled(!isInEditMode)
                    
                    if isInEditMode {
                        Button(action: {
                            withAnimation {
                                edited.append("")
                            }
                        }) {
                            Text("항목 추가")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("과제 및 준비물")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(isInEditMode)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isInEditMode {
                        Button(action: {
                            withAnimation {
                                isInEditMode = false
                                self.edited = self.initialValue
                            }
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
                                self.initialValue = self.edited
                            }
                            
                            // Write data to Firebase Realtime DB
                            guard let uid = Auth.auth().currentUser?.uid else { return }
                            Database.database().reference().child("/calendar/\(uid)/\(formatForDB.string(from: date))/reminder").setValue(edited)
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
            .onAppear() {
                if let reminderToArray = reminderContent as? [String] {
                    self.initialValue = reminderToArray
                    self.edited = reminderToArray
                }
            }
        }
    }
}

struct ReminderDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ReminderDetailsView(reminderContent: ["Test data 1", "Test data 2"], date: Date())
        }
        .accentColor(.white)
    }
}
