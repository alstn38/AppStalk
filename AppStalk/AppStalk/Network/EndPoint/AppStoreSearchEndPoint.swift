//
//  AppStoreSearchEndPoint.swift
//  AppStalk
//
//  Created by 강민수 on 4/24/25.
//

import Foundation

enum AppStoreSearchEndPoint: Router {
    case search(term: String, offset: Int = 1)
}

extension AppStoreSearchEndPoint {
    typealias ErrorType = AppStoreNetworkError
    
    var baseURL: String {
        return Secret.AppStoreBaseURL
    }

    var path: String {
        switch self {
        case .search:
            return "/search"
        }
    }

    var method: HTTPMethod {
        return .get
    }

    var headers: [String: String]? { nil }

    var parameters: [String: Any]? {
        switch self {
        case let .search(term, offset):
            return [
                "term": term,
                "entity": "software",
                "country": "KR",
                "limit": 20,
                "lang": "ko_kr",
                "offset": offset
            ]
        }
    }

    var url: URL? {
        URL(string: baseURL + path)
    }
    
    func asURLRequest() throws -> URLRequest {
        guard var urlComponents = URLComponents(string: baseURL + path) else {
            throw ErrorType.invalidURL
        }
        
        if method == .get, let parameters = parameters {
            urlComponents.queryItems = parameters.map { key, value in
                URLQueryItem(name: key, value: String(describing: value))
            }
        }

        guard let finalURL = urlComponents.url else {
            throw ErrorType.invalidURL
        }

        var request = URLRequest(url: finalURL)
        request.httpMethod = method.rawValue

        return request
    }

    func throwError(error: Error?, statusCode: Int?) -> AppStoreNetworkError {
        if error is DecodingError {
            return .decodingFailed
        }

        if let urlError = error {
            return .network(urlError)
        }

        if let code = statusCode {
            return .httpStatus(code: code)
        }

        return .notHTTPResponse
    }
}
