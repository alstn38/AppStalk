//
//  AppDownloadInfoDTO.swift
//  AppStalk
//
//  Created by 강민수 on 4/25/25.
//

import Foundation
import RealmSwift

final class AppDownloadInfoDTO: Object {
    
    @Persisted(primaryKey: true) var appId: Int
    @Persisted var appName: String
    @Persisted var iconURL: String
    @Persisted var downloadState: String
    /// 다운로드 시작 시간
    @Persisted var startTime: Date?
    /// 다운로드 일시정지 시간
    @Persisted var pausedTime: Date?
    /// 남은 다운로드 시간(초)
    @Persisted var remainingSeconds: Double
    /// 마지막 업데이트 시간
    @Persisted var lastUpdated: Date?
    /// 백그라운드 진입 시간
    @Persisted var currentBackgroundDate: Date?
    
    convenience init(dto: AppInfoDTO) {
        self.init()
        self.appId = dto.id
        self.appName = dto.trackName
        self.iconURL = dto.artworkUrl512
        self.downloadState = DownloadState.ready.rawValue
        self.startTime = Date()
        self.pausedTime = nil
        self.remainingSeconds = 30.0
        self.lastUpdated = nil
        self.currentBackgroundDate = nil
    }
}
