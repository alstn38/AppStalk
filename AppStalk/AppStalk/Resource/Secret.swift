//
//  Secret.swift
//  AppStalk
//
//  Created by 강민수 on 4/24/25.
//

import Foundation

enum Secret {
    
    static let AppStoreBaseURL: String = {
        guard let urlString = Bundle.main.infoDictionary?["APPSTORE_BASE_URL"] as? String else {
            fatalError("APPSTORE_BASE_URL ERROR")
        }
        
        return urlString
    }()
}
