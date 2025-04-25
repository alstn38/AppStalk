//
//  AppDownloadInfoEntity.swift
//  AppStalk
//
//  Created by 강민수 on 4/25/25.
//

import Foundation

struct AppDownloadInfoEntity {
    let appId: Int
    let appName: String
    let iconURL: String
    let downloadState: DownloadState
    let startTime: Date?
    let pausedTime: Date?
    let remainingSeconds: Double
    let lastUpdated: Date?
    let currentBackgroundDate: Date?
}
