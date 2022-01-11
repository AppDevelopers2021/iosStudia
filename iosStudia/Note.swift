//
//  Note.swift
//  iosStudia
//
//  Created by 이종우 on 2022/01/07.
//

import SwiftUI

struct Note : Identifiable {
    var id = UUID()
    var subject: String
    var content: String
}

let testData = [
    Note(subject: "국어", content: "국어 노트"),
    Note(subject: "영어", content: "English Note"),
    Note(subject: "수학", content: "다항함수의 미분법")
]

