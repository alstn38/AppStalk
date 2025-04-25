//
//  SearchAppRow.swift
//  AppStalk
//
//  Created by 강민수 on 4/25/25.
//

import SwiftUI
import Kingfisher

struct SearchAppRow: View {
    
    let app: AppInfoEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                KFImage(URL(string: app.artworkUrl512))
                    .placeholder {
                        Color.gray.opacity(0.2)
                    }
                    .cancelOnDisappear(true)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(app.trackName)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(app.artistName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                AppDownloadButton(app: app)
            }
            .padding(.top)
            .padding(.horizontal)
            
            HStack {
                Text("iOS \(app.minimumOsVersion)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                HStack {
                    Image(systemName: "person.crop.square")
                        .frame(width: 10, height: 10)
                        .foregroundColor(.secondary)
                }
                
                Text(app.artistName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                Text(app.primaryGenreName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding()

            if app.downloadState != .completed {
                ScreenshotCarousel(urls: app.screenshotUrls)
            }
        }
        .padding()
    }
}
