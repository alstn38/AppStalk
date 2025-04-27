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
    @StateObject private var viewModel = AppDownloadButtonViewModel()
    
    var body: some View {
        Button {
            handleButtonTap()
        } label: {
            buttonContent
        }
        .onAppear {
            viewModel.setupApp(app)
            updateAnimationIfNeeded()
        }
        .onChange(of: app.remainingSeconds) { _, _ in
            updateAnimationIfNeeded()
        }
        .onChange(of: app.downloadState) { _, _ in
            viewModel.setupApp(app)
            updateAnimationIfNeeded()
        }
    }
    
    @ViewBuilder
    private var buttonContent: some View {
        switch app.downloadState {
        case .ready, .reinstall:
            Text(app.downloadState == .ready ? "받기" : "다시받기")
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

        case .paused:
            ZStack {
                Circle()
                    .stroke(lineWidth: 2)
                    .foregroundColor(.gray.opacity(0.4))
                    .frame(width: 30, height: 30)

                Circle()
                    .trim(from: 0, to: CGFloat(app.progress))
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 30, height: 30)

                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 10, weight: .bold))
            }

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
    
    private func handleButtonTap() {
        viewModel.handleButtonTap()
    }
    
    private func updateAnimationIfNeeded() {
        // 다운로드 중인 경우에만 애니메이션 적용
        if app.downloadState == .downloading {
            let currentProgress = app.progress
            let remainingTime = max(app.remainingSeconds, 0)
            
            // 이미 진행된 부분은 애니메이션 없이 즉시 적용
            withAnimation(.linear(duration: 0)) {
                animatedProgress = currentProgress
            }

            // 남은 시간만큼 애니메이션 적용
            withAnimation(.linear(duration: remainingTime)) {
                animatedProgress = 1.0
            }
        } else if app.downloadState == .paused {
            // 일시정지 상태에서는 애니메이션 없이 현재 진행도 표시
            withAnimation(.linear(duration: 0)) {
                animatedProgress = app.progress
            }
        } else if app.downloadState == .completed {
            // 완료 상태에서는 진행도 100%
            withAnimation(.linear(duration: 0.3)) {
                animatedProgress = 1.0
            }
        }
    }
}

extension AppInfoEntity {
    var progress: Double {
        // 진행도는 0~1 사이의 값으로 정규화
        let percent = max(0, min(1, 1.0 - (remainingSeconds / 30.0)))
        return percent
    }
}
