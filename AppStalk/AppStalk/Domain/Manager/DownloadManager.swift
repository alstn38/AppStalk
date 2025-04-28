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
    
    /// 앱 상태 변경 발행자
    let appStateChanged = PassthroughSubject<Int, Never>()
    
    /// 앱 초기 상태 처리 여부 플래그
    private var hasProcessedInitialState = false
    
    private init(
        localStorageService: LocalStorageService = DIContainer.shared.resolve(LocalStorageService.self)
    ) {
        self.localStorageService = localStorageService
        setupNotifications()
        setupNetworkMonitoring()
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
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }
    
    /// 네트워크 연결이 끊어진 경우 다운로드 일시정지 하는 메서드
    private func setupNetworkMonitoring() {
        NetworkMonitor.shared.onStateChange = { [weak self] isConnected in
            guard let self = self else { return }
            
            Task {
                if !isConnected {
                    await self.pauseAllDownloadsForNetworkLoss()
                }
            }
        }
    }
    
    /// 모든 다운로드 항목에 대해 백그라운드 진입 Date값 설정하는 메서드
    @objc private func applicationDidEnterBackground() {
        let currentDate = Date()
        
        for (appId, _) in downloadTasks {
            DispatchQueue.main.async {
                Task {
                    try? await self.localStorageService.updateBackgroundDate(
                        appId: appId,
                        date: currentDate
                    )
                }
            }
        }
    }
    
    /// 앱 진입 시점 (앱 켜진 시점 or 단순 Foreground 진입에 따른 처리)
    @objc private func applicationWillEnterForeground() {
        Task {
            /// 앱 초기 진입했을 경우
            if !hasProcessedInitialState {
                await restoreDownloadTasks()
                hasProcessedInitialState = true
            } else {
                /// 단순 Foreground 진입
                await processBackgroundTime()
            }
        }
    }
    
    /// 앱 종료 시점 (다운로드 중인 id 저장) 메서드
    @objc private func applicationWillTerminate() {
        let currentDate = Date()
        
        /// 앱 종료 시간을  저장
        let defaults = UserDefaults.standard
        defaults.set(currentDate.timeIntervalSince1970, forKey: "AppTerminationTime")
        
        /// downloadTasks의 모든 앱 ID를 배열로 저장
        let activeAppIds = Array(downloadTasks.keys)
        defaults.set(activeAppIds, forKey: "ActiveDownloadAppIds")
        
        /// 모든 다운로드 항목에 대해 상태 정보 저장
        for (appId, task) in downloadTasks {
            
            let appKey = "AppDownload_\(appId)"
            defaults.set(task.state.rawValue, forKey: "\(appKey)_state")
            defaults.set(task.remainingSeconds, forKey: "\(appKey)_remainingSeconds")
            defaults.set(currentDate.timeIntervalSince1970, forKey: "\(appKey)_backgroundDate")
        }
        
        /// 모든 변경사항 즉시 동기화
        defaults.synchronize()
    }
    
    /// 네트워크 연결 끊김 시 모든 다운로드 중인 앱 일시정지
    private func pauseAllDownloadsForNetworkLoss() async {
        for (appId, task) in downloadTasks {
            if task.state == .downloading {
                task.pause()
                do {
                    try await localStorageService.updateDownloadState(
                        appId: appId,
                        state: .paused,
                        remainingSeconds: task.remainingSeconds
                    )
                    /// 상태 변경 알림
                    appStateChanged.send(appId)
                } catch {
                    print("네트워크 연결 실패로 다운로드 일시정지 중 오류: \(error)")
                }
            }
        }
    }
    
    /// 앱 다운로드 시작
    func startDownload(app: AppInfoDTO) async {
        let dto = AppDownloadInfoDTO(dto: app)
        
        /// 로컬 저장소에 다운로드 정보 저장
        do {
            try await localStorageService.saveDownloadInfo(dto: dto)
            
            /// 새 다운로드 태스크 생성 및 시작
            let task = createDownloadTask(
                appId: app.id,
                state: .downloading,
                remainingSeconds: 30.0
            )
            
            /// 해당 task 시작과 변경 알림
            task.start()
            appStateChanged.send(app.id)
        } catch {
            print("다운로드 정보 저장 실패: \(error)")
        }
    }
    
    /// 다운로드 상태 시작/재개
    func resumeDownload(appId: Int) async {
        do {
            /// 다운로드 정보 가져오기
            guard let info = try await localStorageService.fetchDownloadInfo(appId: appId) else { return }
            
            /// 이미 완료된 상태면 무시
            guard info.downloadState != .completed else { return }
            
            /// 네트워크 연결 상태 확인
            guard NetworkMonitor.shared.isConnected else { return }
            
            /// 기존 태스크가 있으면 재개
            if let task = downloadTasks[appId] {
                task.start()
            } else {
                /// 태스크가 없으면 새로 생성하고 시작
                let task = createDownloadTask(
                    appId: appId,
                    state: .downloading,
                    remainingSeconds: info.remainingSeconds
                )
                
                task.start()
            }
            
            /// 상태를 downloading으로 업데이트
            try await localStorageService.updateDownloadState(
                appId: appId,
                state: .downloading,
                remainingSeconds: info.remainingSeconds
            )
            
            /// 백그라운드 진입 시간 초기화
            try await localStorageService.updateBackgroundDate(appId: appId, date: nil)
            
            /// 상태 변경 알림
            appStateChanged.send(appId)
        } catch {
            print("다운로드 재개 실패: \(error)")
        }
    }
    
    /// 다운로드 일시정지
    func pauseDownload(appId: Int) async {
        guard let task = downloadTasks[appId] else { return }
        
        /// 타이머 일시 정지
        task.pause()
        
        do {
            /// 상태 업데이트
            try await localStorageService.updateDownloadState(
                appId: appId,
                state: .paused,
                remainingSeconds: task.remainingSeconds
            )
            
            /// 상태 변경 알림
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
    private func createDownloadTask(
        appId: Int,
        state: DownloadState,
        remainingSeconds: Double
    ) -> DownloadTask {
        /// 기존 태스크가 있으면 제거
        if let existingTask = downloadTasks[appId] {
            existingTask.invalidateTimer()
        }
        
        let task = DownloadTask(
            appId: appId,
            state: state,
            remainingSeconds: remainingSeconds
        )
        
        task.onStateChanged = { [weak self] appId, state, remainingSeconds in
            Task { @MainActor in
                /// 상태 변경 시 DB 업데이트
                try? await self?.localStorageService.updateDownloadState(
                    appId: appId,
                    state: state,
                    remainingSeconds: remainingSeconds
                )
                
                /// 변경 알림 발행
                self?.appStateChanged.send(appId)
                
                /// 완료된 경우 태스크 삭제
                if state == .completed {
                    self?.downloadTasks.removeValue(forKey: appId)
                }
            }
        }
        
        downloadTasks[appId] = task
        return task
    }
    
    /// 백그라운드 진입 시간 업데이트
    private func updateBackgroundDate(appId: Int, date: Date?) async {
        try? await localStorageService.updateBackgroundDate(appId: appId, date: date)
    }
    
    /// 백그라운드에서 경과한 시간 처리
    private func processBackgroundTime() async {
        
        /// 현재 다운로드 중인 앱 목록 가져오기
        let downloadingApps = await fetchDownloadingApps()
        
        for app in downloadingApps {
            /// 백그라운드 진입 시간이 기록된 경우에만 처리
            if let backgroundDate = app.currentBackgroundDate {
                let now = Date()
                
                /// 백그라운드에서 지난 시간 기록
                let elapsedSeconds = now.timeIntervalSince(backgroundDate)
                
                /// 남은 시간 계산
                let newRemainingSeconds = max(0, app.remainingSeconds - elapsedSeconds)
                
                /// 백그라운드에서 다운로드가 완료된 경우 완료로 저장.
                if newRemainingSeconds <= 0 && app.downloadState == .downloading {
                    try? await localStorageService.updateDownloadState(
                        appId: app.appId,
                        state: .completed,
                        remainingSeconds: 0
                    )
                    /// 상태 변경 알림
                    appStateChanged.send(app.appId)
                } else {
                    /// 원래 상태가 다운로드 중이며 아직 다운로드가 완료가 안된 경우
                    if app.downloadState == .downloading {
                        /// 네트워크 연결 확인
                        if NetworkMonitor.shared.isConnected {
                            /// 기존 태스크 제거 후 새 태스크로 계속 다운로드
                            if let existingTask = downloadTasks[app.appId] {
                                existingTask.invalidateTimer()
                                downloadTasks.removeValue(forKey: app.appId)
                            }
                            
                            let task = createDownloadTask(
                                appId: app.appId,
                                state: .downloading,
                                remainingSeconds: newRemainingSeconds
                            )
                            
                            task.start()
                        } else {
                            /// 네트워크 연결이 없으면 일시정지
                            try? await localStorageService.updateDownloadState(
                                appId: app.appId,
                                state: .paused,
                                remainingSeconds: newRemainingSeconds
                            )
                        }
                    }
                    
                    appStateChanged.send(app.appId)
                }
                
                /// 백그라운드 진입 시간 초기화
                try? await localStorageService.updateBackgroundDate(appId: app.appId, date: nil)
            }
        }
    }
    
    /// 진행 중이던 다운로드 작업 복구 메서드 (앱 재진입시)
    private func restoreDownloadTasks() async {
        let defaults = UserDefaults.standard
        
        /// 종료 시간과 활성 다운로드 앱 ID가 있는지 확인
        guard
            let terminationTime = defaults.object(forKey: "AppTerminationTime") as? Double,
            let activeAppIds = defaults.object(forKey: "ActiveDownloadAppIds") as? [Int],
            !activeAppIds.isEmpty
        else { return }
        
        let terminationDate = Date(timeIntervalSince1970: terminationTime)
        let now = Date()
        let elapsedSeconds = now.timeIntervalSince(terminationDate)
        
        for appId in activeAppIds {
            do {
                /// UserDefaults에서 저장된 상태 정보 가져오기
                let appKey = "AppDownload_\(appId)"
                let stateString = defaults.string(forKey: "\(appKey)_state") ?? DownloadState.paused.rawValue
                let remainingSeconds = defaults.double(forKey: "\(appKey)_remainingSeconds")
                let state = DownloadState(rawValue: stateString) ?? .paused
                
                /// 상태에 따른 처리
                var newRemainingSeconds = remainingSeconds
                var finalState = state
                
                /// 다운로드 중이었다면 시간 계산 및 상태 변경
                if state == .downloading {
                    newRemainingSeconds = max(0, remainingSeconds - elapsedSeconds)
                    finalState = newRemainingSeconds <= 0 ? .completed : .paused
                }
                
                /// 상태 업데이트
                try await localStorageService.updateDownloadState(
                    appId: appId,
                    state: finalState,
                    remainingSeconds: newRemainingSeconds
                )
                
                /// 완료되지 않은 경우 태스크 생성
                if finalState != .completed {
                    _ = createDownloadTask(
                        appId: appId,
                        state: finalState,
                        remainingSeconds: newRemainingSeconds
                    )
                }
                
                /// 백그라운드 날짜 초기화
                try await localStorageService.updateBackgroundDate(appId: appId, date: nil)
                
                /// 상태 변경 알림
                appStateChanged.send(appId)
                
                /// UserDefaults 앱별 키 삭제
                defaults.removeObject(forKey: "\(appKey)_state")
                defaults.removeObject(forKey: "\(appKey)_remainingSeconds")
                defaults.removeObject(forKey: "\(appKey)_backgroundDate")
            } catch {
                print("앱 ID \(appId) 복구 실패: \(error)")
            }
        }
        
        /// 전역 키 삭제
        defaults.removeObject(forKey: "AppTerminationTime")
        defaults.removeObject(forKey: "ActiveDownloadAppIds")
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
