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
    
    // 앱 초기 상태 처리 여부 플래그
    private var hasProcessedInitialState = false
    
    private init(localStorageService: LocalStorageService = DIContainer.shared.resolve(LocalStorageService.self)) {
        self.localStorageService = localStorageService
        setupNotifications()
        setupNetworkMonitoring()
        
        // 초기화 시점에는 진행 중이던 다운로드 태스크 복구를 진행하지 않음
        // applicationWillEnterForeground에서 통합하여 처리
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
    
    private func setupNetworkMonitoring() {
        NetworkMonitor.shared.onStateChange = { [weak self] isConnected in
            guard let self = self else { return }
            
            Task {
                if !isConnected {
                    // 네트워크 연결이 끊어진 경우 다운로드 일시정지
                    await self.pauseAllDownloadsForNetworkLoss()
                }
            }
        }
    }
    
    @objc private func applicationDidEnterBackground() {
        let currentDate = Date()
        print("앱이 백그라운드로 전환됨: \(currentDate)")
        
        // 모든 다운로드 항목에 대해 백그라운드 날짜 설정 (상태와 무관하게)
        for (appId, _) in downloadTasks {
            // 동기식으로 처리하기 위해 DispatchQueue.main.sync 사용
            DispatchQueue.main.async {
                Task {
                    try? await self.localStorageService.updateBackgroundDate(appId: appId, date: currentDate)
                    print("백그라운드 진입 시간 기록: 앱 ID \(appId)")
                }
            }
        }
    }
    
    @objc private func applicationWillEnterForeground() {
        print("앱이 포그라운드로 복귀함")
        
        Task {
            if !hasProcessedInitialState {
                // 앱 시작 후 첫 포그라운드 진입 시 초기 복구 작업 수행
                print("앱 초기 상태 처리 시작")
                await restoreDownloadTasks()
                hasProcessedInitialState = true
                print("초기 복구 작업 완료")
            } else {
                // 이후 포그라운드 진입 시에는 백그라운드 시간만 처리
                print("일반 백그라운드 → 포그라운드 전환 처리")
                await processBackgroundTime()
            }
        }
    }
    
    @objc private func applicationWillTerminate() {
        print("앱이 종료됨")
        let currentDate = Date()
        
        // UserDefaults를 사용하여 앱 종료 시간을 빠르게 저장
        let defaults = UserDefaults.standard
        defaults.set(currentDate.timeIntervalSince1970, forKey: "AppTerminationTime")
        
        // downloadTasks의 모든 앱 ID를 배열로 저장
        let activeAppIds = Array(downloadTasks.keys)
        defaults.set(activeAppIds, forKey: "ActiveDownloadAppIds")
        
        // 모든 다운로드 항목에 대해 상태 정보 저장
        for (appId, task) in downloadTasks {
            print("앱 꺼지기 전 등장했던 아이디는 바로 \(appId) \(task.state.rawValue)")
            
            // 1. UserDefaults에 중요 정보 빠르게 저장 (백업용)
            let appKey = "AppDownload_\(appId)"
            defaults.set(task.state.rawValue, forKey: "\(appKey)_state")
            defaults.set(task.remainingSeconds, forKey: "\(appKey)_remainingSeconds")
            defaults.set(currentDate.timeIntervalSince1970, forKey: "\(appKey)_backgroundDate")
            
            // 2. 비동기 작업 시도 (가능한 경우만 실행됨)
            Task {
                // 백그라운드 날짜 설정 (종료 시간으로)
                try? await localStorageService.updateBackgroundDate(appId: appId, date: currentDate)
                
                // 다운로드 중인 항목은 일시정지로 변경
                if task.state == .downloading {
                    try? await localStorageService.updateDownloadState(
                        appId: appId,
                        state: .paused,
                        remainingSeconds: task.remainingSeconds
                    )
                    print("앱 종료 전 다운로드 상태 저장: 앱 ID \(appId), 남은 시간: \(task.remainingSeconds)")
                }
            }
        }
        
        // 모든 변경사항 즉시 동기화
        defaults.synchronize()
    }
    
    /// 네트워크 연결 끊김 시 모든 다운로드 일시정지
    private func pauseAllDownloadsForNetworkLoss() async {
        print("네트워크 연결이 끊어짐 - 모든 다운로드 일시정지")
        
        for (appId, task) in downloadTasks {
            if task.state == .downloading {
                task.pause()
                
                do {
                    try await localStorageService.updateDownloadState(
                        appId: appId,
                        state: .paused,
                        remainingSeconds: task.remainingSeconds
                    )
                    print("네트워크 연결 끊김으로 다운로드 일시정지: 앱 ID \(appId)")
                    
                    // 상태 변경 알림
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
            
            // 네트워크 연결 상태 확인
            if !NetworkMonitor.shared.isConnected {
                print("네트워크 연결이 없어 다운로드를 재개할 수 없습니다.")
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
        print("백그라운드 시간 처리 시작")
        
        // 백그라운드 날짜가 설정된 모든 앱 가져오기
        let downloadingApps = await fetchDownloadingApps()
        
        for app in downloadingApps {
            // 백그라운드 진입 시간이 기록된 경우에만 처리
            if let backgroundDate = app.currentBackgroundDate {
                let now = Date()
                let elapsedSeconds = now.timeIntervalSince(backgroundDate)
                print("앱 ID \(app.appId)의 백그라운드 경과 시간: \(elapsedSeconds)초")
                
                // 남은 시간 계산
                let newRemainingSeconds = max(0, app.remainingSeconds - elapsedSeconds)
                
                if newRemainingSeconds <= 0 {
                    // 백그라운드에서 다운로드가 완료된 경우
                    try? await localStorageService.updateDownloadState(
                        appId: app.appId,
                        state: .completed,
                        remainingSeconds: 0
                    )
                    
                    print("백그라운드에서 다운로드 완료: 앱 ID \(app.appId)")
                    
                    // 상태 변경 알림
                    appStateChanged.send(app.appId)
                } else {
                    // 원래 상태가 다운로드 중이었던 경우
                    if app.downloadState == .downloading {
                        // 네트워크 연결 확인
                        if NetworkMonitor.shared.isConnected {
                            // 기존 태스크 제거 후 새 태스크로 계속 다운로드
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
                            print("백그라운드 후 다운로드 계속: 앱 ID \(app.appId), 남은 시간: \(newRemainingSeconds)")
                        } else {
                            // 네트워크 연결이 없으면 일시정지
                            try? await localStorageService.updateDownloadState(
                                appId: app.appId,
                                state: .paused,
                                remainingSeconds: newRemainingSeconds
                            )
                            print("네트워크 연결 없음, 다운로드 일시정지: 앱 ID \(app.appId)")
                        }
                    } else {
                        // 일시정지 상태인 경우 남은 시간만 업데이트
                        try? await localStorageService.updateDownloadState(
                            appId: app.appId,
                            state: app.downloadState,
                            remainingSeconds: newRemainingSeconds
                        )
                        print("상태 유지: 앱 ID \(app.appId), 업데이트된 남은 시간: \(newRemainingSeconds)")
                    }
                    
                    // 상태 변경 알림
                    appStateChanged.send(app.appId)
                }
                
                // 백그라운드 진입 시간 초기화
                try? await localStorageService.updateBackgroundDate(appId: app.appId, date: nil)
            }
        }
    }
    
    /// 진행 중이던 다운로드 작업 복구
    private func restoreDownloadTasks() async {
        print("다운로드 작업 복구 시작")
        
        do {
            // 모든 다운로드 정보 가져오기 (완료된 항목 제외)
            let downloadingApps = try await localStorageService.fetchDownloadingInfos()
            print("복구할 다운로드 작업 수: \(downloadingApps.count)")
            
            // UserDefaults에서 앱 종료 시간 확인
            let defaults = UserDefaults.standard
            if let terminationTime = defaults.object(forKey: "AppTerminationTime") as? Double {
                let terminationDate = Date(timeIntervalSince1970: terminationTime)
                
                // UserDefaults에 저장된 활성 다운로드 앱 ID 배열 확인
                if let activeAppIds = defaults.object(forKey: "ActiveDownloadAppIds") as? [Int] {
                    for appId in activeAppIds {
                        // UserDefaults에서 백업된 상태 정보 확인
                        let appKey = "AppDownload_\(appId)"
                        let stateString = defaults.string(forKey: "\(appKey)_state") ?? DownloadState.paused.rawValue
                        let remainingSeconds = defaults.double(forKey: "\(appKey)_remainingSeconds")
                        
                        // 이 앱에 대한 Realm 정보가 있는지 확인
                        if let _ = try? await localStorageService.fetchDownloadInfo(appId: appId) {
                            // UserDefaults에서 가져온 정보로 Realm 업데이트
                            let state = DownloadState(rawValue: stateString) ?? .paused
                            
                            // 종료 시간 이후 경과한 시간 계산
                            let now = Date()
                            let elapsedSeconds = now.timeIntervalSince(terminationDate)
                            let newRemainingSeconds = max(0, remainingSeconds - elapsedSeconds)
                            
                            if newRemainingSeconds <= 0 {
                                // 종료 후 다운로드가 완료된 경우
                                try await localStorageService.updateDownloadState(
                                    appId: appId,
                                    state: .completed,
                                    remainingSeconds: 0
                                )
                                print("종료 후 다운로드 완료 처리: 앱 ID \(appId)")
                            } else {
                                // 아직 완료되지 않은 경우, 일시정지 상태로 설정
                                try await localStorageService.updateDownloadState(
                                    appId: appId,
                                    state: .paused,
                                    remainingSeconds: newRemainingSeconds
                                )
                                print("종료 후 다운로드 일시정지로 설정: 앱 ID \(appId), 남은 시간: \(newRemainingSeconds)")
                            }
                            
                            // 백그라운드 날짜 초기화
                            try await localStorageService.updateBackgroundDate(appId: appId, date: nil)
                            
                            // 상태 변경 알림
                            appStateChanged.send(appId)
                        }
                    }
                }
                
                // UserDefaults 정보 삭제 (사용 후)
                defaults.removeObject(forKey: "AppTerminationTime")
                defaults.removeObject(forKey: "ActiveDownloadAppIds")
            }
            
            // 기존 코드 실행 - Realm 정보 기반 복구
            for app in downloadingApps {
                // 백그라운드 날짜가 있는 경우 - 정상적인 백그라운드 처리나 앱 종료 시 설정된 값
                if let backgroundDate = app.currentBackgroundDate {
                    let now = Date()
                    let elapsedSeconds = now.timeIntervalSince(backgroundDate)
                    print("앱 ID \(app.appId)의 백그라운드/종료 후 경과 시간: \(elapsedSeconds)초")
                    
                    let newRemainingSeconds = max(0, app.remainingSeconds - elapsedSeconds)
                    
                    if newRemainingSeconds <= 0 {
                        // 이미 다운로드가 완료되었을 경우
                        try await localStorageService.updateDownloadState(
                            appId: app.appId,
                            state: .completed,
                            remainingSeconds: 0
                        )
                        
                        print("앱 실행 시 발견된 완료된 다운로드: 앱 ID \(app.appId)")
                    } else {
                        // 앱이 종료된 경우, 모든 다운로드는 일시정지 상태로 변경
                        try await localStorageService.updateDownloadState(
                            appId: app.appId,
                            state: .paused,
                            remainingSeconds: newRemainingSeconds
                        )
                        
                        // 태스크 생성 (일시정지 상태)
                        _ = createDownloadTask(
                            appId: app.appId,
                            state: .paused,
                            remainingSeconds: newRemainingSeconds
                        )
                        
                        print("앱 재시작 후 다운로드 일시정지 상태로 복구: 앱 ID \(app.appId), 남은 시간: \(newRemainingSeconds)")
                    }
                    
                    // 상태 변경 알림
                    appStateChanged.send(app.appId)
                    
                    // 백그라운드 진입 시간 초기화
                    try await localStorageService.updateBackgroundDate(appId: app.appId, date: nil)
                } else {
                    // 백그라운드 날짜가 없는 경우 - 비정상 종료된 것으로 간주하고 보수적으로 처리
                    // 다운로드 중이었던 항목은 일시정지로 설정
                    if app.downloadState == .downloading {
                        try await localStorageService.updateDownloadState(
                            appId: app.appId,
                            state: .paused,
                            remainingSeconds: app.remainingSeconds
                        )
                    }
                    
                    // 태스크 생성
                    _ = createDownloadTask(
                        appId: app.appId,
                        state: app.downloadState == .downloading ? .paused : app.downloadState,
                        remainingSeconds: app.remainingSeconds
                    )
                    
                    print("비정상 종료 후 작업 복구: 앱 ID \(app.appId), 상태: \(app.downloadState == .downloading ? "paused" : app.downloadState.rawValue)")
                    
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
