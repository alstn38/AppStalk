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
    func fetchCompletedDownloadInfos() async throws -> [AppDownloadInfoEntity]
    func fetchDownloadingInfos() async throws -> [AppDownloadInfoEntity]
    func deleteDownloadInfo(appId: Int) async throws
    func saveDownloadInfo(dto: AppDownloadInfoDTO) async throws
    func updateDownloadState(appId: Int, state: DownloadState, remainingSeconds: Double) async throws
    func updateBackgroundDate(appId: Int, date: Date?) async throws
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
    
    func fetchCompletedDownloadInfos() async throws -> [AppDownloadInfoEntity] {
        let completedObjects = realm.objects(AppDownloadInfoDTO.self)
            .where { $0.downloadState == DownloadState.completed.rawValue }

        return completedObjects.map { object in
            AppDownloadInfoEntity(
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
    
    func fetchDownloadingInfos() async throws -> [AppDownloadInfoEntity] {
        let downloadingObjects = realm.objects(AppDownloadInfoDTO.self)
            .where {
                $0.downloadState == DownloadState.downloading.rawValue ||
                $0.downloadState == DownloadState.paused.rawValue
            }

        return downloadingObjects.map { object in
            AppDownloadInfoEntity(
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
    
    func deleteDownloadInfo(appId: Int) async throws {
        guard let object = realm.object(ofType: AppDownloadInfoDTO.self, forPrimaryKey: appId) else {
            return
        }
        try realm.write {
            object.downloadState = DownloadState.reinstall.rawValue
            object.lastUpdated = Date()
            object.remainingSeconds = 30.0
            object.pausedTime = nil
            object.currentBackgroundDate = nil
        }
    }
    
    func saveDownloadInfo(dto: AppDownloadInfoDTO) async throws {
        try realm.write {
            realm.add(dto, update: .modified)
        }
    }
    
    func updateDownloadState(appId: Int, state: DownloadState, remainingSeconds: Double) async throws {
        guard let object = realm.object(ofType: AppDownloadInfoDTO.self, forPrimaryKey: appId) else {
            return
        }
        
        try realm.write {
            object.downloadState = state.rawValue
            object.remainingSeconds = remainingSeconds
            object.lastUpdated = Date()
            
            // 일시정지인 경우 일시정지 시간 기록
            if state == .paused {
                object.pausedTime = Date()
            } else if state == .downloading {
                object.pausedTime = nil
            }
        }
    }
    
    func updateBackgroundDate(appId: Int, date: Date?) async throws {
        guard let object = realm.object(ofType: AppDownloadInfoDTO.self, forPrimaryKey: appId) else {
            return
        }
        
        try realm.write {
            object.currentBackgroundDate = date
        }
    }
}
