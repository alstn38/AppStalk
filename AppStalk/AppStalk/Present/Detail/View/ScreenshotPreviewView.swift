//
//  ScreenshotPreviewView.swift
//  AppStalk
//
//  Created by 강민수 on 4/26/25.
//

import SwiftUI
import Kingfisher

struct ScreenshotPreviewView: View {
    
    let screenshots: [String]
    let onTap: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("미리 보기")
                .font(.title3.bold())
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(screenshots.indices, id: \.self) { index in
                        KFImage(URL(string: screenshots[index]))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 200)
                            .cornerRadius(10)
                            .onTapGesture {
                                onTap(index)
                            }
                    }
                }
            }
        }
    }
}
