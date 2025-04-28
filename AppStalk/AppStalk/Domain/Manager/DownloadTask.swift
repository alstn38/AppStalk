//
//  DownloadTask.swift
//  AppStalk
//
//  Created by 강민수 on 4/26/25.
//

import Foundation

/// 개별 앱의 다운로드 진행을 관리하는 클래스
final class DownloadTask {
    let appId: Int
    var state: DownloadState
    var remainingSeconds: Double
    private var timer: Timer?
    
    var onStateChanged: ((Int, DownloadState, Double) -> Void)?
    private var dispatchTimer: DispatchSourceTimer?
    private var lastUpdatedTime: Date?
    
    init(appId: Int, state: DownloadState, remainingSeconds: Double) {
        self.appId = appId
        self.state = state
        self.remainingSeconds = remainingSeconds
    }
    
    deinit {
        print("DownloadTask for app \(appId) is being deallocated!")
        invalidateTimer()
    }
    
    /// 다운로드 시작/재개
    func start() {
        // 완료된 경우는 무시
        print("DownloadTask.start() called for app: \(appId)")
        guard state != .completed else { return }
        
        // 상태 변경
        print("Changing state to downloading")
        state = .downloading
        lastUpdatedTime = Date()
        
        // 타이머 시작
        print("Starting timer")
        startTimer()
        
        // 콜백 호출
        print("Calling state changed callback")
        onStateChanged?(appId, state, remainingSeconds)
        print("start() method completed")
    }
    
    /// 다운로드 일시정지
    func pause() {
        // 다운로드 중인 경우만 일시정지 가능
        guard state == .downloading else { return }
        
        // 타이머 중지
        invalidateTimer()
        
        // 상태 변경
        state = .paused
        
        // 콜백 호출
        onStateChanged?(appId, state, remainingSeconds)
    }
    
    /// 타이머 시작
    private func startTimer() {
        print("startTimer called, current remainingSeconds: \(remainingSeconds)")
        stopDispatchTimer() // 기존 타이머 중지
        print("Previous timer invalidated")

        print("Creating new dispatch timer")
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        timer.schedule(deadline: .now(), repeating: .milliseconds(100))
        timer.setEventHandler { [weak self] in
            guard let self = self, self.state == .downloading else {
                return
            }
            
            self.remainingSeconds -= 0.1
            self.remainingSeconds = (self.remainingSeconds * 10).rounded() / 10
            
            if self.remainingSeconds <= 0 {
                print("Time reached zero, completing download")
                self.complete()
            } else if self.remainingSeconds.truncatingRemainder(dividingBy: 1.0) < 0.1 {
                // 1초마다 상태 업데이트
                self.onStateChanged?(self.appId, self.state, self.remainingSeconds)
            }
        }
        
        self.dispatchTimer = timer
        timer.resume()
        print("Dispatch timer started")
    }
    
    private func stopDispatchTimer() {
        if let timer = dispatchTimer {
            timer.cancel()
            dispatchTimer = nil
            print("Dispatch timer cancelled")
        }
    }
    
    /// 다운로드 완료 처리
    private func complete() {
        print("Complete method called! Remaining: \(remainingSeconds)")
        // 타이머 중지
        invalidateTimer()
        
        // 상태 변경
        state = .completed
        remainingSeconds = 0
        print("State changed to: \(state.rawValue)")
        
        // 콜백 호출 (완료 상태 알림)
        if Thread.isMainThread {
            onStateChanged?(self.appId, self.state, self.remainingSeconds)
        } else {
            DispatchQueue.main.async {
                self.onStateChanged?(self.appId, self.state, self.remainingSeconds)
            }
        }
        print("Callback should have been called")
    }
    
    /// 타이머 무효화
    func invalidateTimer() {
        stopDispatchTimer()
        timer?.invalidate()
        timer = nil
    }
}
