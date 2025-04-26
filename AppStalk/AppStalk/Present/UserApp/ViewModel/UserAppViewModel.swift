//
//  UserAppViewModel.swift
//  AppStalk
//
//  Created by 강민수 on 4/26/25.
//

import Foundation
import Combine

final class UserAppViewModel: ViewModelType {

    struct Input {
        let onAppear = PassthroughSubject<Void, Never>()
        let queryChanged = PassthroughSubject<String, Never>()
        let deleteApp = PassthroughSubject<AppDownloadInfoEntity, Never>()
    }

    struct Output {
        var filteredApps: [AppDownloadInfoEntity] = []
    }

    @Published var input = Input()
    @Published var output = Output()

    var cancellables = Set<AnyCancellable>()

    private let appSearchRepository: AppSearchRepository
    private var allApps: [AppDownloadInfoEntity] = []
    private var currentQuery: String = ""

    init(
        appSearchRepository: AppSearchRepository = DIContainer.shared.resolve(AppSearchRepository.self)
    ) {
        self.appSearchRepository = appSearchRepository
        transform()
    }

    func transform() {
        input.onAppear
            .sink { [weak self] in
                Task {
                    await self?.fetchMyApps()
                }
            }
            .store(in: &cancellables)

        input.queryChanged
            .removeDuplicates()
            .sink { [weak self] text in
                self?.currentQuery = text
                self?.filterApps(with: text)
            }
            .store(in: &cancellables)

        input.deleteApp
            .sink { [weak self] app in
                Task {
                    await self?.delete(app)
                }
            }
            .store(in: &cancellables)
            
        // 다운로드 상태 변화 구독 - 앱이 완료 상태로 변경되면 목록에 추가
        appSearchRepository.downloadStateChanged
            .receive(on: RunLoop.main)
            .sink { [weak self] appId in
                Task {
                    await self?.checkAndAddCompletedApp(appId: appId)
                }
            }
            .store(in: &cancellables)
    }

    private func fetchMyApps() async {
        do {
            let apps = try await appSearchRepository.fetchMyAppResult()
            await MainActor.run {
                self.allApps = apps
                self.output.filteredApps = apps
            }
        } catch {
            print("내 앱 가져오기 실패: \(error)")
        }
    }

    private func filterApps(with query: String) {
        if query.isEmpty {
            output.filteredApps = allApps
        } else {
            output.filteredApps = allApps.filter { $0.appName.localizedCaseInsensitiveContains(query) }
        }
    }

    private func delete(_ app: AppDownloadInfoEntity) async {
        do {
            try await appSearchRepository.deleteMyApp(appId: app.appId)
            await MainActor.run {
                self.allApps.removeAll { $0.appId == app.appId }
                self.filterApps(with: self.currentQuery)
            }
        } catch {
            print("앱 삭제 실패: \(error)")
        }
    }
    
    // 다운로드가 완료된 앱인지 확인하고 목록에 추가
    private func checkAndAddCompletedApp(appId: Int) async {
        do {
            if let appInfo = try await appSearchRepository.fetchDownloadInfo(appId: appId),
               appInfo.downloadState == .completed,
               !self.allApps.contains(where: { $0.appId == appId }) {
                
                // 완료된 앱이 목록에 없으면 추가
                await MainActor.run {
                    self.allApps.append(appInfo)
                    self.filterApps(with: self.currentQuery)
                }
            }
        } catch {
            print("앱 정보 확인 실패: \(error)")
        }
    }
}
