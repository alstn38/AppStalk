//
//  ScreenshotCarousel.swift
//  AppStalk
//
//  Created by 강민수 on 4/25/25.
//

import SwiftUI
import Kingfisher

struct ScreenshotCarousel: View {
    let urls: [String]
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(urls.prefix(3), id: \.self) { url in
                KFImage(URL(string: url))
                    .placeholder {
                        ZStack {
                            Color.gray.opacity(0.1)
                            ProgressView()
                        }
                    }
                    .resizable()
                    .cancelOnDisappear(true)
                    .scaledToFit()
                    .clipped()
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal)
    }
}
