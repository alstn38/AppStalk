//
//  SearchView.swift
//  AppStalk
//
//  Created by 강민수 on 4/24/25.
//

import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = AppSearchViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(viewModel.output.searchResults, id: \.id) { app in
                        NavigationLink(value: app) {
                            SearchAppRow(app: app)
                        }
                    }
                    if viewModel.output.isLoadingMore {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("검색")
            .searchable(text: $viewModel.input.query, prompt: "게임, 앱, 스토리 등")
            .onSubmit(of: .search) {
                viewModel.input.searchSubmitted.send(())
            }
            .refreshable {
                // TODO: 다시 새로고침
            }
            .navigationDestination(for: AppInfoEntity.self) { app in
                // TODO: DetailView 이동
            }
        }
    }
}
