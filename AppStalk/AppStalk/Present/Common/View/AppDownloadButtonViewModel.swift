//
//  AppDownloadButtonViewModel.swift
//  AppStalk
//
//  Created by 강민수 on 4/26/25.
//

import Foundation
import Combine

final class AppDownloadButtonViewModel: ObservableObject {
    
    private var app: AppInfoEntity?
    private let appSearchRepository: AppSearchRepository
    
    init(appSearchRepository: AppSearchRepository = DIContainer.shared.resolve(AppSearchRepository.self)) {
        self.appSearchRepository = appSearchRepository
    }
    
    func setupApp(_ app: AppInfoEntity) {
        self.app = app
    }
    
    func handleButtonTap() {
        guard let app = app else { return }
        
        switch app.downloadState {
        case .ready, .reinstall:
            // 네트워크 연결 확인
            if !NetworkMonitor.shared.isConnected {
                print("네트워크 연결이 없어 다운로드를 시작할 수 없습니다.")
                return
            }
            
            let downloadInfoDTO = AppDownloadInfoDTO()
            downloadInfoDTO.appId = app.id
            downloadInfoDTO.appName = app.trackName
            downloadInfoDTO.iconURL = app.artworkUrl512
            downloadInfoDTO.downloadState = DownloadState.downloading.rawValue
            downloadInfoDTO.startTime = Date()
            downloadInfoDTO.remainingSeconds = 30.0
            
            Task {
                // 로컬 저장소에 다운로드 정보 저장
                try? await DIContainer.shared.resolve(LocalStorageService.self).saveDownloadInfo(dto: downloadInfoDTO)
                
                // 다운로드 시작
                await appSearchRepository.resumeDownload(appId: app.id)
            }
            
        case .downloading:
            // 다운로드 일시정지
            Task {
                await appSearchRepository.pauseDownload(appId: app.id)
            }
            
        case .paused:
            // 네트워크 연결 확인
            if !NetworkMonitor.shared.isConnected {
                print("네트워크 연결이 없어 다운로드를 재개할 수 없습니다.")
                return
            }
            
            // 다운로드 재개
            Task {
                await appSearchRepository.resumeDownload(appId: app.id)
            }
            
        case .completed:
            // 열기 액션 - 앱 실행 (시뮬레이션만 함)
            print("앱 실행: \(app.trackName)")
        }
    }
}
