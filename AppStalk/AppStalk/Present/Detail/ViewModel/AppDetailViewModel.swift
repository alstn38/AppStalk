//
//  AppDetailViewModel.swift
//  AppStalk
//
//  Created by 강민수 on 4/26/25.
//

import Foundation
import Combine

final class AppDetailViewModel: ViewModelType {
    
    struct Input {
        let screenshotTapped = PassthroughSubject<Int, Never>()
        let dismissScreenshot = PassthroughSubject<Void, Never>()
        let onAppear = PassthroughSubject<AppInfoEntity, Never>()
    }

    struct Output {
        var selectedScreenshotIndex: Int? = nil
        var isShowingScreenshotViewer: Bool = false
        var app: AppInfoEntity?
    }
    
    var input = Input()
    @Published var output = Output()
    
    var cancellables = Set<AnyCancellable>()
    private let appSearchRepository: AppSearchRepository
    
    init(appSearchRepository: AppSearchRepository = DIContainer.shared.resolve(AppSearchRepository.self)) {
        self.appSearchRepository = appSearchRepository
        transform()
    }
    
    func transform() {
        // 스크린샷 탭
        input.screenshotTapped
            .sink { [weak self] index in
                self?.output.selectedScreenshotIndex = index
                self?.output.isShowingScreenshotViewer = true
            }
            .store(in: &cancellables)

        // 전체화면 닫기
        input.dismissScreenshot
            .sink { [weak self] in
                self?.output.selectedScreenshotIndex = nil
                self?.output.isShowingScreenshotViewer = false
            }
            .store(in: &cancellables)
            
        // 앱 상세 화면 등장 시 현재 앱 설정
        input.onAppear
            .sink { [weak self] app in
                self?.output.app = app
            }
            .store(in: &cancellables)
            
        // 다운로드 상태 변화 구독
        appSearchRepository.downloadStateChanged
            .receive(on: RunLoop.main)
            .sink { [weak self] appId in
                guard let self = self, let currentApp = self.output.app, currentApp.id == appId else { return }
                Task { @MainActor in
                  self.updateAppState(appId: appId)
                }
            }
            .store(in: &cancellables)
    }
    
    // 앱 상태가 변경되면 현재 보고 있는 앱의 상태 업데이트
    @MainActor
    private func updateAppState(appId: Int) {
        Task {
            do {
                guard let downloadInfo = try await appSearchRepository.fetchDownloadInfo(appId: appId),
                      var updatedApp = output.app,
                      updatedApp.id == appId else { return }
                
                // 앱 상태 업데이트
                updatedApp.downloadState = downloadInfo.downloadState
                updatedApp.remainingSeconds = downloadInfo.remainingSeconds
                
                // 변경된 앱으로 업데이트
                output.app = updatedApp
            } catch {
                print("앱 상태 업데이트 실패: \(error)")
            }
        }
    }
    
    private func clearSelectedScreenshot() {
        output.selectedScreenshotIndex = nil
    }
}
