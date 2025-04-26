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
    }

    struct Output {
        var selectedScreenshotIndex: Int? = nil
        var isShowingScreenshotViewer: Bool = false
    }
    
    var input = Input()
    @Published var output = Output()
    
    var cancellables = Set<AnyCancellable>()

    init() {
        transform()
    }
    
    func transform() {
        /// 스크린샷 탭
        input.screenshotTapped
            .sink { [weak self] index in
                self?.output.selectedScreenshotIndex = index
                self?.output.isShowingScreenshotViewer = true
            }
            .store(in: &cancellables)

        /// 전체화면 닫기
        input.dismissScreenshot
            .sink { [weak self] in
                self?.output.selectedScreenshotIndex = nil
                self?.output.isShowingScreenshotViewer = false
            }
            .store(in: &cancellables)
    }
    
    private func clearSelectedScreenshot() {
        output.selectedScreenshotIndex = nil
    }
}
