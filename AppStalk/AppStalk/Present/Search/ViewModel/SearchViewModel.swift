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
    }

    struct Output {
        var searchResults: [AppInfoEntity] = []
        var isLoadingMore: Bool = false
    }

    @Published var input = Input()
    @Published var output = Output()

    var cancellables = Set<AnyCancellable>()

    private var currentPage = 1
    private var isLoading = false
    private let appSearchRepository: AppSearchRepository
    
    init() {
        self.appSearchRepository = DIContainer.shared.resolve(AppSearchRepository.self)
        transform()
    }

    func transform() {
        input.searchSubmitted
            .sink { [weak self] in
                Task {
                    await self?.search(term: self?.input.query ?? "")
                }
            }
            .store(in: &cancellables)
    }

    func search(term: String, isRefresh: Bool = false) async {
        guard !term.isEmpty else { return }
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
                output.isLoadingMore = false
            }
        } catch {
            print("검색 실패: \(error)")
        }
    }

    func loadNextPageIfNeeded(current app: AppInfoEntity) {
        guard let last = output.searchResults.last else { return }
        if last.id == app.id && !isLoading {
            output.isLoadingMore = true
            Task {
                await search(term: input.query)
            }
        }
    }
}
