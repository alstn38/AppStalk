//
//  ViewModelType.swift
//  AppStalk
//
//  Created by 강민수 on 4/25/25.
//

import Foundation
import Combine

protocol ViewModelType: AnyObject, ObservableObject {
    associatedtype Input
    associatedtype Output

    var cancellables: Set<AnyCancellable> { get set }
    var input: Input { get set }
    var output: Output { get set }

    func transform()
}
