//
//  AppSearchRepository.swift
//  AppStalk
//
//  Created by 강민수 on 4/25/25.
//

import Foundation
import Combine

protocol AppSearchRepository {
    /// 앱스토어 검색 결과를 불러오고 로컬 상태와 병합하여 Entity 목록 반환
    func fetchSearchResult(term: String, offset: Int) async throws -> [AppInfoEntity]
    
    /// 다운로드된 앱 Entity 목록 반환
    func fetchMyAppResult() async throws -> [AppDownloadInfoEntity]
    
    /// 다운로드된 앱 삭제
    func deleteMyApp(appId: Int) async throws
    
    /// 앱 다운로드 시작
    func startDownload(app: AppInfoDTO) async
    
    /// 앱 다운로드 재개
    func resumeDownload(appId: Int) async
    
    /// 앱 다운로드 일시정지
    func pauseDownload(appId: Int) async
    
    /// 앱 다운로드 정보 조회
    func fetchDownloadInfo(appId: Int) async throws -> AppDownloadInfoEntity?
    
    /// 다운로드 상태 변경 퍼블리셔
    var downloadStateChanged: AnyPublisher<Int, Never> { get }
}

final class DefaultAppSearchRepository: AppSearchRepository {
    
    private let networkManager: NetworkService
    private let localStorageService: LocalStorageService
    private let downloadManager: DownloadManager
    
    init(
        networkManager: NetworkService = .shared,
        localStorageService: LocalStorageService = DIContainer.shared.resolve(LocalStorageService.self),
        downloadManager: DownloadManager = .shared
    ) {
        self.networkManager = networkManager
        self.localStorageService = localStorageService
        self.downloadManager = downloadManager
    }
    
    func fetchDownloadInfo(appId: Int) async throws -> AppDownloadInfoEntity? {
        return try await localStorageService.fetchDownloadInfo(appId: appId)
    }
    
    var downloadStateChanged: AnyPublisher<Int, Never> {
        downloadManager.appStateChanged.eraseToAnyPublisher()
    }
    
    func fetchSearchResult(term: String, offset: Int) async throws -> [AppInfoEntity] {
        let router = AppStoreSearchEndPoint.search(term: term, offset: offset)
        let responseDTO = try await networkManager.request(router: router, responseType: SearchResponseDTO.self)
        
        var resultEntities: [AppInfoEntity] = []
        
        for appDTO in responseDTO.results {
            let localInfo = try? await localStorageService.fetchDownloadInfo(appId: appDTO.id)
            
            // 로컬 정보가 있으면 그 상태를, 없으면 .ready 상태로 설정
            let downloadState = localInfo?.downloadState ?? .ready
            let remainingSeconds = localInfo?.remainingSeconds ?? 30.0
            
            resultEntities.append(
                AppInfoEntity(
                    id: appDTO.id,
                    trackName: appDTO.trackName,
                    description: appDTO.description,
                    artworkUrl512: appDTO.artworkUrl512,
                    screenshotUrls: appDTO.screenshotUrls,
                    artistName: appDTO.artistName,
                    price: appDTO.price,
                    version: appDTO.version,
                    primaryGenreName: appDTO.primaryGenreName,
                    bundleId: appDTO.bundleId,
                    minimumOsVersion: appDTO.minimumOsVersion,
                    currentVersionReleaseDate: appDTO.currentVersionReleaseDate,
                    releaseNotes: appDTO.releaseNotes,
                    formattedPrice: appDTO.formattedPrice,
                    contentAdvisoryRating: appDTO.contentAdvisoryRating,
                    downloadState: downloadState,
                    remainingSeconds: remainingSeconds
                )
            )
        }
        
        return resultEntities
    }
    
    func fetchMyAppResult() async throws -> [AppDownloadInfoEntity] {
        return try await localStorageService.fetchCompletedDownloadInfos()
    }
    
    func deleteMyApp(appId: Int) async throws {
        try await localStorageService.deleteDownloadInfo(appId: appId)
        downloadManager.appStateChanged.send(appId)
    }
    
    func startDownload(app: AppInfoDTO) async {
        print("Starting download for app: \(app.id)")
        await downloadManager.startDownload(app: app)
    }
    
    func resumeDownload(appId: Int) async {
        print("Resuming download for app: \(appId)")
        await downloadManager.resumeDownload(appId: appId)
    }
    
    func pauseDownload(appId: Int) async {
        print("pause download for app: \(appId)")
        await downloadManager.pauseDownload(appId: appId)
    }
}
