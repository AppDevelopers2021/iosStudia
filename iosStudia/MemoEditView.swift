//
//  MemoEditView.swift
//  iosStudia
//
//  Created by 이종우 on 2022/01/07.
//

import SwiftUI

struct MemoEditView: View {
    var body: some View {
        VStack {
            Text("hello wolrd")
        }
        .navigationTitle("메모 수정")
    }
}

struct MemoEditView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {MemoEditView()}
    }
}
