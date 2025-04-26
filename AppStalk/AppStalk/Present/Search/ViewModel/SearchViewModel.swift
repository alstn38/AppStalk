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
        var isEmptyResult: Bool {
            !isLoading && searchResults.isEmpty
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
    }

    private func search(term: String, isRefresh: Bool = false) async {
        guard !term.isEmpty else { return }
        
        // output.isLoading이 실행되어야지 넘어감.
        await MainActor.run {
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
                    output.searchResults += results
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
}
