//
//  TabBarView.swift
//  AppStalk
//
//  Created by 강민수 on 4/24/25.
//

import SwiftUI

struct TabBarView: View {
    
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Image(systemName: "text.rectangle.page")
                    Text("투데이")
                }

            GameView()
                .tabItem {
                    Image(systemName: "gamecontroller")
                    Text("게임")
                }
            
            UserAppView()
                .tabItem {
                    Image(systemName: "square.stack.3d.up.fill")
                    Text("앱")
                }
            
            ArcadeView()
                .tabItem {
                    Image(systemName: "arcade.stick")
                    Text("Arcade")
                }
            
            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("검색")
                }
        }
        .tint(.accentColor)
    }
}
