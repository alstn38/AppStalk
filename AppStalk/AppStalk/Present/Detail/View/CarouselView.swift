//
//  CarouselView.swift
//  AppStalk
//
//  Created by 강민수 on 4/26/25.
//

import SwiftUI
import Kingfisher

struct CarouselView: View {
    
    let urls: [String]
    @Binding var currentIndex: Int?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(urls.indices, id: \.self) { index in
                    KFImage(URL(string: urls[index]))
                        .resizable()
                        .scaledToFit()
                        .frame(width: UIScreen.main.bounds.width * 0.9)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                        .id(index)
                }
            }
            .padding(.horizontal, (UIScreen.main.bounds.width * 0.1) / 2)
            .scrollTargetLayout()
        }
        .scrollPosition(id: $currentIndex)
        .scrollTargetBehavior(.viewAligned)
    }
}
