//
//  NetworkError.swift
//  AppStalk
//
//  Created by 강민수 on 4/24/25.
//

import Foundation

enum AppStoreNetworkError: Error {
    case invalidURL
    case decodingFailed
    case httpStatus(code: Int)
    case notHTTPResponse
    case network(Error)
    case unknown
}

extension AppStoreNetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "유효하지 않은 URL입니다."
        case .decodingFailed:
            return "응답 데이터를 디코딩하는 데 실패했습니다."
        case .httpStatus(let code):
            return "HTTP 오류가 발생했습니다. 상태 코드: \(code)"
        case .notHTTPResponse:
            return "서버 응답이 HTTP 형식이 아닙니다."
        case .network(let error):
            return "네트워크 오류: \(error.localizedDescription)"
        case .unknown:
            return "알 수 없는 오류가 발생했습니다."
        }
    }
}
