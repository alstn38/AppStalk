//
//  UpdateNoteView.swift
//  AppStalk
//
//  Created by 강민수 on 4/26/25.
//

import SwiftUI

struct UpdateNoteView: View {

    let app: AppInfoEntity

    @State private var isExpanded = false
    @State private var showMoreButton = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("새로운 소식")
                    .font(.title3.bold())

                Spacer()

                Text(relativeDateText(from: app.currentVersionReleaseDate))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Text("버전 \(app.version)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(app.releaseNotes ?? "")
                .font(.body)
                .lineLimit(isExpanded ? nil : 3)
                .fixedSize(horizontal: false, vertical: true)
                .background(
                    TextHeightReader(text: app.releaseNotes ?? "", lineLimit: 3) { isTruncated in
                        showMoreButton = isTruncated
                    }
                )

            if showMoreButton {
                Button {
                    withAnimation {
                        isExpanded.toggle()
                    }
                } label: {
                    Text(isExpanded ? "접기" : "더 보기")
                        .font(.subheadline.bold())
                }
            }
        }
    }

    private func relativeDateText(from isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else { return "" }

        let diff = Calendar.current.dateComponents([.day], from: date, to: Date())
        if let days = diff.day, days < 7 {
            return "\(days)일 전"
        } else {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "yyyy-MM-dd"
            return displayFormatter.string(from: date)
        }
    }
}
