//
//  AppInfoEntity.swift
//  AppStalk
//
//  Created by 강민수 on 4/25/25.
//

import Foundation

struct AppInfoEntity {
    /// 앱 ID (Identifiable 준수용)
    let id: Int
    /// 앱 이름
    let trackName: String
    /// 앱 설명 (짧은 버전)
    let description: String?
    /// 앱 아이콘 URL (512x512)
    let artworkUrl512: String
    /// 앱 스크린샷 URL 목록
    let screenshotUrls: [String]
    /// 앱 개발사
    let artistName: String
    /// 앱 가격
    let price: Double
    /// 앱 버전
    let version: String
    /// 앱 카테고리
    let primaryGenreName: String
    /// 앱 번들 ID
    let bundleId: String
    /// 최소 OS 버전
    let minimumOsVersion: String
    /// 출시 날짜
    let releaseDate: String
    /// 릴리즈 노트 설명
    let releaseNotes: String?
    /// 앱 가격 문자열
    let formattedPrice: String
    
    var downloadState: DownloadState
    var remainingSeconds: Double
}
