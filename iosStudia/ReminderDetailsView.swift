//
//  ReminderDetailsView.swift
//  iosStudia
//
//  Created by 이종우 on 2022/02/03.
//

import SwiftUI
import Firebase

struct ReminderDetailsView: View {
    @State var isInEditMode: Bool = false   // Let user edit stuff if true
    @State var initialValue: [String] = []  // To put back initial value when user cancels edit
    @State var edited: [String] = []        // Edited content to write to DB
    
    // Variables passed on from CalendarView
    var reminderContent: NSArray
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
            Color("BgColor")
            VStack {
                List {
                    ForEach(Array(edited.indices), id: \.self) { index in
                        TextField("내용 입력", text: Binding(
                            get: { return edited[index] },
                            set: { (newValue) in return self.edited[index] = newValue }
                        ))
                            .disabled(!isInEditMode)    // Enable editing only in EditMode
                            .accentColor(.blue)
                    }
                    .onDelete { indexSet in
                        // When user swipes to delete
                        edited.remove(atOffsets: indexSet)
                    }
                    .deleteDisabled(!isInEditMode)      // Enable swipe only in EditMode
                    
                    if isInEditMode {
                        // Add Item button
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
                        // Cancel button
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
                        // Done button
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
                        // Edit button
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
                // Convert to @State variable
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
        ReminderDetailsView(reminderContent: ["Test Value for Live Preview"], date: Date())
    }
}
