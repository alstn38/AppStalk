//
//  AppDetailView.swift
//  AppStalk
//
//  Created by 강민수 on 4/26/25.
//

import SwiftUI


struct AppDetailView: View {
    
    let app: AppInfoEntity
    @StateObject private var viewModel = AppDetailViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AppHeaderView(app: app)

                AppInfoScrollView(app: app)

                UpdateNoteView(app: app)

                ScreenshotPreviewView(
                    screenshots: app.screenshotUrls,
                    onTap: { index in
                        viewModel.input.screenshotTapped.send(index)
                    }
                )
            }
            .padding()
        }
        .fullScreenCover(isPresented: $viewModel.output.isShowingScreenshotViewer) {
            ScreenshotFullScreenView(
                app: app,
                initialIndex: viewModel.output.selectedScreenshotIndex ?? 0
            )
        }
    }
}
