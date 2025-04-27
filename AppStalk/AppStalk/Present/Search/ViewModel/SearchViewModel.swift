//
//  SearchViewModel.swift
//  AppStalk
//
//  Created by 강민수 on 4/25/25.
//

import Foundation
import Combine

final class AppSearchViewModel: ViewModelType {

    struct Input {
        var query: String = ""
        let searchSubmitted = PassthroughSubject<Void, Never>()
        let currentShowItem = PassthroughSubject<AppInfoEntity, Never>()
    }

    struct Output {
        var searchResults: [AppInfoEntity] = []
        var isLoading: Bool = false
        var hasSearched: Bool = false
        var isEmptyResult: Bool {
            hasSearched && !isLoading && searchResults.isEmpty
        }
    }

    var input = Input()
    @Published var output = Output()

    var cancellables = Set<AnyCancellable>()

    private var currentPage = 1
    private let appSearchRepository: AppSearchRepository
    
    init() {
        self.appSearchRepository = DIContainer.shared.resolve(AppSearchRepository.self)
        transform()
    }

    func transform() {
        input.searchSubmitted
            .sink { [weak self] in
                guard let self else { return }
                Task {
                    await self.search(term: self.input.query, isRefresh: true)
                }
            }
            .store(in: &cancellables)
        
        input.currentShowItem
            .sink { [weak self] appInfo in
                self?.loadNextPageIfNeeded(current: appInfo)
            }
            .store(in: &cancellables)
        
        // 다운로드 상태 변화 구독
        appSearchRepository.downloadStateChanged
            .receive(on: RunLoop.main)
            .sink { [weak self] appId in
                guard let self = self else { return }
                Task { @MainActor in
                    self.updateAppStateInSearchResults(appId: appId)
                }
            }
            .store(in: &cancellables)
    }

    private func search(term: String, isRefresh: Bool = false) async {
        guard !term.isEmpty else { return }
        
        // output.isLoading이 실행되어야지 넘어감.
        await MainActor.run {
            output.hasSearched = true
            output.isLoading = true
        }
        
        // 메인 스레드에서 새로운 Task를 비동기적으로 실행.
        defer {
            Task { @MainActor in
                output.isLoading = false
            }
        }
        
        if isRefresh {
            currentPage = 1
        }
        do {
            let results = try await appSearchRepository.fetchSearchResult(term: term, offset: currentPage)
            await MainActor.run {
                if isRefresh || currentPage == 1 {
                    output.searchResults = results
                } else {
                    // 중복 아이템을 방지하고 새 결과만 추가
                    let newItems = results.filter { newItem in
                        !output.searchResults.contains { $0.id == newItem.id }
                    }
                    output.searchResults.append(contentsOf: newItems)
                }
                currentPage += 1
            }
        } catch {
            print("검색 실패: \(error)")
        }
    }

    private func loadNextPageIfNeeded(current app: AppInfoEntity) {
        guard let last = output.searchResults.last else { return }
        if last.id == app.id && !output.isLoading {
            Task {
                await search(term: input.query)
            }
        }
    }
    
    // 앱 상태가 변경되면 검색 결과 목록에서 해당 앱의 상태 업데이트
    @MainActor
    private func updateAppStateInSearchResults(appId: Int) {
        Task {
            do {
                guard let downloadInfo = try await appSearchRepository.fetchDownloadInfo(appId: appId) else { return }
                
                // 검색 결과에서 해당 앱을 찾아 상태 업데이트
                var updatedResults = output.searchResults
                
                for index in 0..<updatedResults.count {
                    if updatedResults[index].id == appId {
                        updatedResults[index].downloadState = downloadInfo.downloadState
                        updatedResults[index].remainingSeconds = downloadInfo.remainingSeconds
                    }
                }
                
                // 업데이트된 결과로 출력값 설정
                output.searchResults = updatedResults
            } catch {
                print("앱 상태 업데이트 실패: \(error)")
            }
        }
    }
}
