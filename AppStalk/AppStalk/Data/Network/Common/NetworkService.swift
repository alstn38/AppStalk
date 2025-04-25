//
//  NetworkService.swift
//  AppStalk
//
//  Created by 강민수 on 4/24/25.
//

import Foundation

final class NetworkService {
    
    static let shared = NetworkService()
    
    private init() { }

    func request<T: Router, U: Decodable>(
        router: T,
        responseType: U.Type
    ) async throws -> U {
        do {
            let request = try router.asURLRequest()
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw router.throwError(error: nil, statusCode: nil)
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw router.throwError(error: nil, statusCode: httpResponse.statusCode)
            }

            do {
                return try JSONDecoder().decode(U.self, from: data)
            } catch {
                throw router.throwError(error: error, statusCode: httpResponse.statusCode)
            }

        } catch {
            throw router.throwError(error: error, statusCode: nil)
        }
    }
}
