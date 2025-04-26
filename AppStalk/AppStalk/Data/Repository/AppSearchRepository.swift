//
//  AppSearchRepository.swift
//  AppStalk
//
//  Created by 강민수 on 4/25/25.
//

import Foundation

protocol AppSearchRepository {
    /// 앱스토어 검색 결과를 불러오고 로컬 상태와 병합하여 Entity 목록 반환
    func fetchSearchResult(term: String, offset: Int) async throws -> [AppInfoEntity]
}

final class DefaultAppSearchRepository: AppSearchRepository {
    
    private let networkManager: NetworkService
    private let localStorageService: LocalStorageService
    
    init(
        networkManager: NetworkService = .shared,
        localStorageService: LocalStorageService = DIContainer.shared.resolve(LocalStorageService.self)
    ) {
        self.networkManager = networkManager
        self.localStorageService = localStorageService
    }
    
    func fetchSearchResult(term: String, offset: Int) async throws -> [AppInfoEntity] {
        let router = AppStoreSearchEndPoint.search(term: term, offset: offset)
        let responseDTO = try await networkManager.request(router: router, responseType: SearchResponseDTO.self)
        
        var resultEntities: [AppInfoEntity] = []
        
        for appDTO in responseDTO.results {
            let localInfo: AppDownloadInfoEntity?
            do {
                localInfo = try await localStorageService.fetchDownloadInfo(appId: appDTO.id)
            } catch {
                throw error
            }
            
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
                    downloadState: localInfo?.downloadState ?? .ready,
                    remainingSeconds: localInfo?.remainingSeconds ?? 30.0
                )
            )
        }
        
        return resultEntities
    }
}
