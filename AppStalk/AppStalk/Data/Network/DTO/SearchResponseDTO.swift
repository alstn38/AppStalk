//
//  SearchResponseDTO.swift
//  AppStalk
//
//  Created by 강민수 on 4/24/25.
//

import Foundation

struct SearchResponseDTO: Decodable {
    /// 검색 결과 개수
    let resultCount: Int
    /// 검색 결과 앱 목록
    let results: [AppInfoDTO]
}

struct AppInfoDTO: Decodable, Identifiable {
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
    /// 앱스토어 URL
    let trackViewUrl: String
    /// 앱 파일 크기 (바이트)
    let fileSizeBytes: String?
    /// 평점
    let averageUserRating: Double?
    /// 평점 수
    let userRatingCount: Int?
    /// 최소 OS 버전
    let minimumOsVersion: String
    /// 출시 날짜
    let releaseDate: String
    /// 앱 개발사 URL
    let sellerUrl: String?
    
    /// 앱 가격 문자열
    let formattedPrice: String
    
    /// CodingKeys 정의
    enum CodingKeys: String, CodingKey {
        case id = "trackId"
        case trackName, description, artworkUrl512, screenshotUrls, artistName
        case price, version, primaryGenreName, bundleId, trackViewUrl
        case fileSizeBytes, averageUserRating, userRatingCount
        case minimumOsVersion, releaseDate, sellerUrl, formattedPrice
    }
}
