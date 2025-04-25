//
//  LocalStorageService.swift
//  AppStalk
//
//  Created by 강민수 on 4/25/25.
//

import Foundation
import RealmSwift

protocol LocalStorageService {
    func fetchDownloadInfo(appId: Int) async throws -> AppDownloadInfoEntity?
}

@MainActor
final class DefaultLocalStorageService: LocalStorageService {
    
    private let realm = try! Realm()
    
    func fetchDownloadInfo(appId: Int) async throws -> AppDownloadInfoEntity? {
        guard let object = realm.object(ofType: AppDownloadInfoDTO.self, forPrimaryKey: appId) else {
            return nil
        }
        
        return AppDownloadInfoEntity(
            appId: object.appId,
            appName: object.appName,
            iconURL: object.iconURL,
            downloadState: DownloadState(rawValue: object.downloadState) ?? .ready,
            startTime: object.startTime,
            pausedTime: object.pausedTime,
            remainingSeconds: object.remainingSeconds,
            lastUpdated: object.lastUpdated,
            currentBackgroundDate: object.currentBackgroundDate
        )
    }
}
