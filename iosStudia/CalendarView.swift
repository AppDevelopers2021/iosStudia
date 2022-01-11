//
//  ContentView.swift
//  iosStudia
//
//  Created by 이종우 on 2022/01/06.
//

import SwiftUI
import Firebase
import GoogleSignIn

struct CalendarView: View {
    @State var selectedDate: Date = Date()
    @State var isPickerOpen: Bool = false
    @State var memo = "Lorem Ipsum Dolor Sit Amet"
    @State var reminders = "Consectetur Adipiscing Elit"
    
    var showValue: String = ""
    var notes: [Note] = testData
    
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
        // Fetch Data from DB
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Database.database().reference().child("calendar/\(uid)/\(formatForDB.string(from: selectedDate))").observe(DataEventType.value, with: { snapshot in
            // parse
        });
    }
    
    init() {
        load()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("ThemeColor").ignoresSafeArea()
                ScrollView() {
                    VStack(spacing: 15) {
                        HStack {
                            // Date Navigation
                            Button(action: {
                                // Date Back
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
                            }) {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(Color("TextColor"))
                                    .font(.system(size: 25))
                                    .padding(.leading, 10)
                            }
                            Spacer()
                            
                            NavigationLink(destination: LoginView()) {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(Color("TextColor"))
                                    .font(.system(size: 25))
                                    .padding(.trailing, 10)
                            }
                        }
                        
                        if isPickerOpen {
                            DatePicker("날짜 선택", selection: $selectedDate, displayedComponents: .date)
                                .datePickerStyle(WheelDatePickerStyle())
                                .labelsHidden()
                                .transition(.scale)
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
                                            .cornerRadius(8)
                                        
                                        Text(note.content)
                                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                    }
                                    .padding(7)
                                    .foregroundColor(Color("TextColor"))
                                    .background(Color("HighlightBgColor"))
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 150, alignment: .leading)
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
                            }
                            .padding([.vertical], 15)
                        }
                        .padding(10)
                        .background(Color("HighlightBgColor"))
                        .cornerRadius(10)
                        
                        Spacer()
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
                    }
                }
            }
        }
        .accentColor(.white)
    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
    }
}
