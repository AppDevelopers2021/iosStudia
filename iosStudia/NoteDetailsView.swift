//
//  NoteDetailsView.swift
//  iosStudia
//
//  Created by 이종우 on 2022/01/07.
//

import SwiftUI

struct NoteDetailsView: View {
    var selectedNote: Note
    
    var body: some View {
        Text("hi")
            .navigationTitle("노트")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                let navigationBarAppearance = UINavigationBar.appearance()
                navigationBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
                navigationBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
                navigationBarAppearance.backgroundColor = UIColor(Color("ThemeColor"))
            }
    }
}

struct NoteDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        NoteDetailsView(selectedNote: testData[0])
    }
}
