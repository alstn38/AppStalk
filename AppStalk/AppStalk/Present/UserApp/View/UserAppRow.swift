//
//  UserAppRow.swift
//  AppStalk
//
//  Created by 강민수 on 4/26/25.
//

import SwiftUI
import Kingfisher

struct UserAppRow: View {
    
    let app: AppDownloadInfoEntity

    var body: some View {
        HStack(spacing: 12) {
            KFImage(URL(string: app.iconURL))
                .resizable()
                .frame(width: 50, height: 50)
                .cornerRadius(10)

            Text(app.appName)
                .font(.headline)
                .lineLimit(1)

            Spacer()

            Text("열기")
                .font(.subheadline.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .foregroundStyle(.blue)
                .background(Color(.systemGray6))
                .cornerRadius(16)
        }
        .padding(.vertical, 8)
    }
}
