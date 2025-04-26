//
//  InfoItemView.swift
//  AppStalk
//
//  Created by 강민수 on 4/26/25.
//

import SwiftUI

struct InfoItemView: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 80)
        .padding()
    }
}
