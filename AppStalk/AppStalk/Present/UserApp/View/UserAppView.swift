//
//  UserAppView.swift
//  AppStalk
//
//  Created by 강민수 on 4/24/25.
//

import SwiftUI

struct UserAppView: View {
    @State private var searchText = ""
    @StateObject private var viewModel = UserAppViewModel()

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.output.filteredApps, id: \.appId) { app in
                    UserAppRow(app: app)
                }
                .onDelete(perform: delete)
            }
            .listStyle(.plain)
            .navigationTitle("앱")
            .searchable(text: $searchText)
            .onChange(of: searchText) { oldValue, newValue in
                viewModel.input.queryChanged.send(newValue)
            }
            .onAppear {
                viewModel.input.onAppear.send(())
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let app = viewModel.output.filteredApps[index]
            viewModel.input.deleteApp.send(app)
        }
    }
}
