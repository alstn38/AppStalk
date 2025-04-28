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
                if viewModel.output.isLoading {
                    ProgressView()
                }
                
                if viewModel.output.isEmptyResult {
                    emptyResultView()
                }
                
                LazyVStack(spacing: 10) {
                    ForEach(viewModel.output.searchResults, id: \.id) { app in
                        NavigationLink(value: app) {
                            SearchAppRow(app: app)
                        }
                        .id(app.id)
                        .onAppear {
                            viewModel.input.currentShowItem.send(app)
                        }
                    }
                }
            }
            .navigationTitle("검색")
            .searchable(text: $viewModel.input.query, prompt: "게임, 앱, 스토리 등")
            .onSubmit(of: .search) {
                viewModel.input.searchSubmitted.send(())
            }
            .refreshable {
                viewModel.input.searchSubmitted.send(())
            }
            .navigationDestination(for: AppInfoEntity.self) { app in
                AppDetailView(app: app)
            }
        }
    }
    
    private func emptyResultView() -> some View {
        VStack {
            Spacer()
            Text("검색 결과가 없습니다.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding()
            Spacer()
        }
    }
}
