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
}
