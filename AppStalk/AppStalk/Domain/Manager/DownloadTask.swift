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
    
    var onStateChanged: ((Int, DownloadState, Double) -> Void)?
    private var dispatchTimer: DispatchSourceTimer?
    private var lastUpdatedTime: Date?
    
    init(appId: Int, state: DownloadState, remainingSeconds: Double) {
        self.appId = appId
        self.state = state
        self.remainingSeconds = remainingSeconds
    }
    
    deinit {
        invalidateTimer()
    }
    
    /// 다운로드 시작/재개
    func start() {
        /// 완료된 경우는 무시
        guard state != .completed else { return }
        
        /// 상태 변경
        state = .downloading
        lastUpdatedTime = Date()
        
        /// 타이머 시작
        startTimer()
        
        /// 콜백 호출
        onStateChanged?(appId, state, remainingSeconds)
    }
    
    /// 다운로드 일시정지
    func pause() {
        /// 다운로드 중인 경우만 일시정지 가능
        guard state == .downloading else { return }
        
        /// 타이머 중지
        invalidateTimer()
        
        /// 상태 변경
        state = .paused
        
        /// 콜백 호출
        onStateChanged?(appId, state, remainingSeconds)
    }
    
    /// 타이머 시작
    private func startTimer() {
        /// 기존 타이머 중지
        stopDispatchTimer()
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        timer.schedule(deadline: .now(), repeating: .milliseconds(100))
        timer.setEventHandler { [weak self] in
            guard let self = self, self.state == .downloading else {
                return
            }
            
            self.remainingSeconds -= 0.1
            self.remainingSeconds = (self.remainingSeconds * 10).rounded() / 10
            
            if self.remainingSeconds <= 0 {
                self.complete()
            } else if self.remainingSeconds.truncatingRemainder(dividingBy: 1.0) < 0.1 {
                self.onStateChanged?(self.appId, self.state, self.remainingSeconds)
            }
        }
        
        self.dispatchTimer = timer
        timer.resume()
    }
    
    private func stopDispatchTimer() {
        if let timer = dispatchTimer {
            timer.cancel()
            dispatchTimer = nil
        }
    }
    
    /// 다운로드 완료 처리
    private func complete() {
        /// 타이머 중지
        invalidateTimer()
        
        /// 상태 변경
        state = .completed
        remainingSeconds = 0
        
        /// 콜백 호출 (완료 상태 알림)
        if Thread.isMainThread {
            onStateChanged?(self.appId, self.state, self.remainingSeconds)
        } else {
            DispatchQueue.main.async {
                self.onStateChanged?(self.appId, self.state, self.remainingSeconds)
            }
        }
    }
    
    /// 타이머 무효화
    func invalidateTimer() {
        stopDispatchTimer()
    }
}
