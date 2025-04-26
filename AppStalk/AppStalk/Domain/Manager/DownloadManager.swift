//
//  DownloadManager.swift
//  AppStalk
//
//  Created by 강민수 on 4/26/25.
//

import Foundation
import Combine
import SwiftUI

/// 앱 다운로드 관리를 담당하는 매니저 클래스
final class DownloadManager {
    
    static let shared = DownloadManager()
    
    private var downloadTasks: [Int: DownloadTask] = [:]
    private let localStorageService: LocalStorageService
    
    // 앱 상태 변경 발행자
    let appStateChanged = PassthroughSubject<Int, Never>()
    
    private init(localStorageService: LocalStorageService = DIContainer.shared.resolve(LocalStorageService.self)) {
        self.localStorageService = localStorageService
        setupNotifications()
        
        // 초기화 시 진행 중이던 다운로드 태스크 복구
        Task {
            await restoreDownloadTasks()
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidEnterBackground),
            name: UIScene.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillEnterForeground),
            name: UIScene.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func applicationDidEnterBackground() {
        // 백그라운드 진입 시간 기록 및 타이머 일시 중지
        let currentDate = Date()
        
        for (appId, task) in downloadTasks {
            if task.state == .downloading {
                // 다운로드 중인 태스크는 백그라운드 시간 기록
                Task {
                    await updateBackgroundDate(appId: appId, date: currentDate)
                }
                // 타이머 일시정지
                task.pause()
            }
        }
    }
    
    @objc private func applicationWillEnterForeground() {
        // 포그라운드 복귀 시 경과 시간 계산하여 타이머 상태 업데이트
        Task {
            await processBackgroundTime()
        }
    }
    
    /// 앱 다운로드 시작
    func startDownload(app: AppInfoDTO) async {
        let dto = AppDownloadInfoDTO(dto: app)
        
        // 로컬 저장소에 다운로드 정보 저장
        do {
            try await localStorageService.saveDownloadInfo(dto: dto)
            
            // 새 다운로드 태스크 생성 및 시작
            let task = createDownloadTask(
                appId: app.id,
                state: .downloading,
                remainingSeconds: 30.0
            )
            
            task.start()
            
            // 상태 변경 알림
            appStateChanged.send(app.id)
        } catch {
            print("다운로드 정보 저장 실패: \(error)")
        }
    }
    
    /// 다운로드 상태 시작/재개
    func resumeDownload(appId: Int) async {
        do {
            // 다운로드 정보 가져오기
            guard let info = try await localStorageService.fetchDownloadInfo(appId: appId) else { return }
            
            // 이미 완료된 상태면 무시
            if info.downloadState == .completed {
                return
            }
            
            // 기존 태스크가 있으면 재개
            if let task = downloadTasks[appId] {
                task.start()
            } else {
                // 태스크가 없으면 새로 생성하고 시작
                let task = createDownloadTask(
                    appId: appId,
                    state: .downloading,
                    remainingSeconds: info.remainingSeconds
                )
                
                task.start()
            }
            
            // 상태를 downloading으로 업데이트
            try await localStorageService.updateDownloadState(
                appId: appId,
                state: .downloading,
                remainingSeconds: info.remainingSeconds
            )
            
            // 백그라운드 진입 시간 초기화
            try await localStorageService.updateBackgroundDate(appId: appId, date: nil)
            
            // 상태 변경 알림
            appStateChanged.send(appId)
        } catch {
            print("다운로드 재개 실패: \(error)")
        }
    }
    
    /// 다운로드 일시정지
    func pauseDownload(appId: Int) async {
        guard let task = downloadTasks[appId] else { return }
        
        // 타이머 일시 정지
        task.pause()
        
        do {
            // 상태 업데이트
            try await localStorageService.updateDownloadState(
                appId: appId,
                state: .paused,
                remainingSeconds: task.remainingSeconds
            )
            
            // 상태 변경 알림
            appStateChanged.send(appId)
        } catch {
            print("다운로드 일시정지 실패: \(error)")
        }
    }
    
    /// 앱 다운로드 정보 가져오기
    private func getDownloadInfo(appId: Int) async -> AppDownloadInfoEntity? {
        do {
            return try await localStorageService.fetchDownloadInfo(appId: appId)
        } catch {
            print("다운로드 정보 가져오기 실패: \(error)")
            return nil
        }
    }
    
    /// 다운로드 태스크 생성
    @discardableResult
    private func createDownloadTask(appId: Int, state: DownloadState, remainingSeconds: Double) -> DownloadTask {
        print("Creating download task for app: \(appId) with state: \(state.rawValue) and remaining seconds: \(remainingSeconds)")
            
        // 기존 태스크가 있으면 제거
        if let existingTask = downloadTasks[appId] {
            existingTask.invalidateTimer()
        }
        
        let task = DownloadTask(appId: appId, state: state, remainingSeconds: remainingSeconds)
        print("Task created successfully")
        task.onStateChanged = { [weak self] appId, state, remainingSeconds in
            print("Task state changed callback: appId=\(appId), state=\(state.rawValue), remaining=\(remainingSeconds)")
            Task { @MainActor in
                // 상태 변경 시 DB 업데이트
                try? await self?.localStorageService.updateDownloadState(
                    appId: appId,
                    state: state,
                    remainingSeconds: remainingSeconds
                )
                
                // 변경 알림 발행
                self?.appStateChanged.send(appId)
                
                // 완료된 경우 태스크 삭제
                if state == .completed {
                    self?.downloadTasks.removeValue(forKey: appId)
                }
            }
        }
        
        downloadTasks[appId] = task
        print("Task added to downloadTasks dictionary")
        return task
    }
    
    /// 백그라운드 진입 시간 업데이트
    private func updateBackgroundDate(appId: Int, date: Date?) async {
        try? await localStorageService.updateBackgroundDate(appId: appId, date: date)
    }
    
    /// 백그라운드에서 경과한 시간 처리
    private func processBackgroundTime() async {
        // 백그라운드에서 복귀했을 때 다운로드 중이던 앱의 상태 업데이트
        let downloadingApps = await fetchDownloadingApps()
        
        for app in downloadingApps {
            // 백그라운드 진입 시간이 기록된 경우
            if let backgroundDate = app.currentBackgroundDate {
                let now = Date()
                let elapsedSeconds = now.timeIntervalSince(backgroundDate)
                
                // 남은 시간 계산
                let newRemainingSeconds = max(0, app.remainingSeconds - elapsedSeconds)
                
                if newRemainingSeconds <= 0 {
                    // 백그라운드에서 다운로드가 완료된 경우
                    try? await localStorageService.updateDownloadState(
                        appId: app.appId,
                        state: .completed,
                        remainingSeconds: 0
                    )
                    
                    // 백그라운드 진입 시간 초기화
                    try? await localStorageService.updateBackgroundDate(appId: app.appId, date: nil)
                    
                    // 상태 변경 알림
                    appStateChanged.send(app.appId)
                } else {
                    if app.downloadState == .downloading {
                        // 이전에 다운로드 중이었던 앱은 재개
                        let task = createDownloadTask(
                            appId: app.appId,
                            state: .downloading,
                            remainingSeconds: newRemainingSeconds
                        )
                        
                        task.start()
                        
                        // 백그라운드 진입 시간 초기화
                        try? await localStorageService.updateBackgroundDate(appId: app.appId, date: nil)
                    } else {
                        // 일시정지 상태였던 앱은 남은 시간만 업데이트
                        try? await localStorageService.updateDownloadState(
                            appId: app.appId,
                            state: .paused,
                            remainingSeconds: newRemainingSeconds
                        )
                        
                        // 백그라운드 진입 시간 초기화
                        try? await localStorageService.updateBackgroundDate(appId: app.appId, date: nil)
                        
                        // 상태 변경 알림
                        appStateChanged.send(app.appId)
                    }
                }
            }
        }
    }
    
    /// 진행 중이던 다운로드 작업 복구
    private func restoreDownloadTasks() async {
        do {
            // 다운로드 중이거나 일시정지된 앱 목록 가져오기
            let downloadingApps = try await localStorageService.fetchDownloadingInfos()
            
            for app in downloadingApps {
                // 백그라운드 날짜가 있는 경우 처리
                if let backgroundDate = app.currentBackgroundDate {
                    let now = Date()
                    let elapsedSeconds = now.timeIntervalSince(backgroundDate)
                    let newRemainingSeconds = max(0, app.remainingSeconds - elapsedSeconds)
                    
                    if newRemainingSeconds <= 0 {
                        // 이미 다운로드가 완료된 경우
                        try await localStorageService.updateDownloadState(
                            appId: app.appId,
                            state: .completed,
                            remainingSeconds: 0
                        )
                        
                        // 상태 변경 알림
                        appStateChanged.send(app.appId)
                    } else {
                        // 태스크 생성
                        _ = createDownloadTask(
                            appId: app.appId,
                            state: app.downloadState,
                            remainingSeconds: newRemainingSeconds
                        )
                        
                        // 다운로드 중이었던 경우 시작
                        if app.downloadState == .downloading {
                            downloadTasks[app.appId]?.start()
                        }
                        
                        // 백그라운드 진입 시간 초기화
                        try await localStorageService.updateBackgroundDate(appId: app.appId, date: nil)
                        
                        // 상태 변경 알림
                        appStateChanged.send(app.appId)
                    }
                } else {
                    // 백그라운드 날짜가 없는 경우 간단히 태스크 생성
                    _ = createDownloadTask(
                        appId: app.appId,
                        state: app.downloadState,
                        remainingSeconds: app.remainingSeconds
                    )
                    
                    // 다운로드 중이었던 경우 시작
                    if app.downloadState == .downloading {
                        downloadTasks[app.appId]?.start()
                    }
                    
                    // 상태 변경 알림
                    appStateChanged.send(app.appId)
                }
            }
        } catch {
            print("다운로드 작업 복구 실패: \(error)")
        }
    }
    
    /// 현재 다운로드 중인 앱 목록 가져오기
    private func fetchDownloadingApps() async -> [AppDownloadInfoEntity] {
        do {
            return try await localStorageService.fetchDownloadingInfos()
        } catch {
            print("다운로드 중인 앱 목록 가져오기 실패: \(error)")
            return []
        }
    }
}
