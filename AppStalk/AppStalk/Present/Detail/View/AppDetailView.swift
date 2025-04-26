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
    @State private var currentApp: AppInfoEntity
    
    init(app: AppInfoEntity) {
        self.app = app
        // 초기 앱 상태 설정
        self._currentApp = State(initialValue: app)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AppHeaderView(app: currentApp)

                AppInfoScrollView(app: currentApp)

                UpdateNoteView(app: currentApp)

                ScreenshotPreviewView(
                    screenshots: currentApp.screenshotUrls,
                    onTap: { index in
                        viewModel.input.screenshotTapped.send(index)
                    }
                )
            }
            .padding()
        }
        .onAppear {
            viewModel.input.onAppear.send(app)
        }
        .fullScreenCover(isPresented: $viewModel.output.isShowingScreenshotViewer) {
            ScreenshotFullScreenView(
                app: currentApp,
                initialIndex: viewModel.output.selectedScreenshotIndex ?? 0
            )
        }
        // 앱 상태 변화 감지
        .onReceive(viewModel.$output) { output in
            if let updatedApp = output.app {
                currentApp = updatedApp
            }
        }
    }
}
