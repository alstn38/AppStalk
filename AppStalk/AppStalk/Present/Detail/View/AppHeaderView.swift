//
//  AppHeaderView.swift
//  AppStalk
//
//  Created by 강민수 on 4/26/25.
//

import SwiftUI
import Kingfisher

struct AppHeaderView: View {
    let app: AppInfoEntity

    var body: some View {
        HStack {
            KFImage(URL(string: app.artworkUrl512))
                .resizable()
                .frame(width: 100, height: 100)
                .cornerRadius(16)

            VStack(alignment: .leading) {
                Text(app.trackName)
                    .font(.title3.bold())
                    .lineLimit(2)
                
                Spacer()

                AppDownloadButton(app: app)
            }
        }
    }
}
