//
//  AppDownloadButton.swift
//  AppStalk
//
//  Created by 강민수 on 4/25/25.
//

import SwiftUI

struct AppDownloadButton: View {
    let app: AppInfoEntity
    @State private var animatedProgress: Double = 0.0

    var body: some View {
        switch app.downloadState {
        case .ready:
            Text("받기")
                .font(.subheadline.bold())
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .foregroundStyle(.blue)
                .background(Color(.systemGray6))
                .cornerRadius(16)

        case .downloading:
            ZStack {
                Circle()
                    .stroke(lineWidth: 2)
                    .foregroundColor(.gray.opacity(0.4))
                    .frame(width: 30, height: 30)

                Circle()
                    .trim(from: 0, to: CGFloat(animatedProgress))
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 30, height: 30)

                Image(systemName: "pause")
                    .font(.system(size: 10, weight: .bold))
            }
            .onAppear {
                startAnimatingProgress()
            }
            .onChange(of: app.remainingSeconds) {
                startAnimatingProgress()
            }

        case .paused:
            Image(systemName: "icloud.and.arrow.down")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.blue)

        case .reinstall:
            Image(systemName: "icloud.and.arrow.down")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.blue)

        case .completed:
            Text("열기")
                .font(.subheadline.bold())
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .foregroundStyle(.blue)
                .background(Color(.systemGray6))
                .cornerRadius(16)
        }
    }
    
    private func startAnimatingProgress() {
        let currentProgress = app.progress
        
        let remainingTime = max(app.remainingSeconds, 0)
        
        animatedProgress = currentProgress

        withAnimation(.linear(duration: remainingTime)) {
            animatedProgress = 1.0
        }
    }
}

private extension AppInfoEntity {
    var progress: Double {
        let percent = max(0, min(1, 1.0 - (remainingSeconds / 30.0)))
        return percent
    }
}
