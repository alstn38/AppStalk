//
//  AppInfoScrollView.swift
//  AppStalk
//
//  Created by 강민수 on 4/26/25.
//

import SwiftUI

struct AppInfoScrollView: View {
    let app: AppInfoEntity

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    InfoItemView(title: "버전", value: "\(app.minimumOsVersion)+")
                    
                    verticalDivider
                    
                    InfoItemView(title: "연령", value: app.contentAdvisoryRating)
                    
                    verticalDivider
                    
                    InfoItemView(title: "카테고리", value: app.primaryGenreName)
                    
                    verticalDivider
                    
                    InfoItemView(title: "개발자", value: app.artistName)
                }
                .frame(height: 80)
                .padding(.horizontal)
            }

            Divider()
        }
    }

    private var verticalDivider: some View {
        Rectangle()
            .frame(width: 1)
            .padding(.vertical, 16)
            .foregroundColor(Color(.systemGray4))
    }
}
