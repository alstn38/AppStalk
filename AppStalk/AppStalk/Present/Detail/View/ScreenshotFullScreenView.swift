//
//  ScreenshotFullScreenView.swift
//  AppStalk
//
//  Created by 강민수 on 4/26/25.
//

import SwiftUI

struct ScreenshotFullScreenView: View {
    
    let app: AppInfoEntity
    let initialIndex: Int

    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int? = 0

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("완료")
                            .font(.subheadline.bold())
                            .foregroundStyle(.blue)
                    }
                    
                    Spacer()
                    
                    AppDownloadButton(app: app)
                }
                .padding()
                
                Spacer()

                CarouselView(
                    urls: app.screenshotUrls,
                    currentIndex: $currentIndex
                )
                .frame(height: UIScreen.main.bounds.height * 0.75)

                Spacer()
            }
        }
        .onAppear {
            currentIndex = initialIndex
        }
    }
}
