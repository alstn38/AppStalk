//
//  UserAppEntity.swift
//  AppStalk
//
//  Created by 강민수 on 4/25/25.
//

import Foundation

struct UserAppEntity {
    /// 앱 ID (Identifiable 준수용)
    let id: Int
    /// 앱 이름
    let trackName: String
    /// 앱 아이콘 URL (512x512)
    let artworkUrl512: String
    /// 마지막 업데이트 날짜
    let lastUpdated: Date
    
    var downloadState: DownloadState
}
