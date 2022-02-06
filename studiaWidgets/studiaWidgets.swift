//
//  studiaWidgets.swift
//  studiaWidgets
//
//  Created by 이종우 on 2022/02/05.
//

import WidgetKit
import SwiftUI
import Firebase

struct Note: Identifiable {
    var id = UUID()
    var subject: String
    var content: String
}

class NetworkManager {
    func fetchNotes(completion: @escaping ([Note]) -> Void) {
        // d
    }
}

struct NoteViewProvider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .never)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct NoteView: View {
    let data: noteWidgetData
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 15) {
                if widgetFamily == .systemMedium {
                    VStack(spacing: 5) {
                        Text("26")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .frame(width: 35, height: 35)
                            .background(Circle().fill(Color("ThemeColor")))
                        
                        Text("월요일")
                            .font(.system(size: 13))
                        
                        Spacer()
                    }
                }
                
                VStack {
                    HStack {
                        VStack(alignment: .leading) {
                            ForEach(data.notes) { note in
                                Text(note.content)
                                    .font(.system(size: 13))
                                    .lineLimit(/*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
                                    .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 0))
                                    .overlay(RoundedRectangle(cornerRadius: 2).frame(width: 4, height: nil, alignment: .leading).foregroundColor(Color.purple), alignment: .leading)
                            }
                        }
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .padding(EdgeInsets(top: 20, leading: 15, bottom: 15, trailing: 15))
        .overlay(Rectangle().frame(width: nil, height: 10, alignment: .top).foregroundColor(Color("ThemeColor")), alignment: .top)
    }
}

struct noteWidgetData {
    let notes: [Note]
}

extension noteWidgetData {
    static let previewData = noteWidgetData(notes: [
        Note(subject: "국어", content: "국어 노트입니다"),
        Note(subject: "수학", content: "뭔가 아주아주아주아주아주아주아주아주아주아아주 긴 노트")
    ])
}

struct noteWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "blue.studia.noteWidget",
            provider: NoteViewProvider()
        ) { entry in
            NoteView(data: .previewData)
        }
        .configurationDisplayName("노트")
        .description("작성한 노트를 빠르게 확인할 수 있습니다.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct studiaWidgets: WidgetBundle {
    var body: some Widget {
        noteWidget()
    }
}

struct studiaWidgets_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NoteView(data: .previewData)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            NoteView(data: .previewData)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
            NoteView(data: .previewData)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .redacted(reason: .placeholder)
        }
    }
}
