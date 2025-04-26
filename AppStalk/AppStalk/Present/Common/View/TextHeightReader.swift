//
//  TextHeightReader.swift
//  AppStalk
//
//  Created by 강민수 on 4/26/25.
//

import SwiftUI

struct TextHeightReader: View {
    
    let text: String
    let lineLimit: Int
    let onTruncationChange: (Bool) -> Void

    var body: some View {
        Text(text)
            .lineLimit(lineLimit)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            let style = NSMutableParagraphStyle()
                            style.lineBreakMode = .byTruncatingTail
                            let attr = NSAttributedString(string: text, attributes: [
                                .font: UIFont.preferredFont(forTextStyle: .body),
                                .paragraphStyle: style
                            ])
                            let limitHeight = (UIFont.preferredFont(forTextStyle: .body).lineHeight * CGFloat(lineLimit))
                            let fullHeight = attr.boundingRect(
                                with: CGSize(width: geometry.size.width, height: .greatestFiniteMagnitude),
                                options: [.usesLineFragmentOrigin, .usesFontLeading],
                                context: nil
                            ).height
                            onTruncationChange(fullHeight > limitHeight)
                        }
                }
            )
            .hidden()
    }
}
