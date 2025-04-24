//
//  Router.swift
//  AppStalk
//
//  Created by 강민수 on 4/24/25.
//

import Foundation

protocol Router {
    associatedtype ErrorType: Error

    var url: URL? { get }
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var parameters: [String: Any]? { get }

    func asURLRequest() throws -> URLRequest
    func throwError(error: Error?, statusCode: Int?) -> ErrorType
}
