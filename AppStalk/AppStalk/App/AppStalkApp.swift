//
//  AppStalkApp.swift
//  AppStalk
//
//  Created by 강민수 on 4/24/25.
//

import SwiftUI

@main
struct AppStalkApp: App {
    
    init() {
        register()
    }
    
    var body: some Scene {
        WindowGroup {
            TabBarView()
        }
    }
    
    private func register() {
        /// Service
        DIContainer.shared.register(LocalStorageService.self, dependency: DefaultLocalStorageService())
        
        /// Repository
        DIContainer.shared.register(AppSearchRepository.self, dependency: DefaultAppSearchRepository())
    }
}
