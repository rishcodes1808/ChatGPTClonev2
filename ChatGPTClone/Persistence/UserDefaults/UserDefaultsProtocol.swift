//
//  UserDefaultsProtocol.swift
//  ChatGPTClone
//
//  Created by Rish on 17/05/25.
//

import Foundation

protocol UserDefaultsProtocol {
    func set(_ value: Any?, forKey defaultName: String)
    func object(forKey defaultName: String) -> Any?
}

extension UserDefaults: UserDefaultsProtocol {}

class MockUserDefaults: UserDefaultsProtocol {
    private var storage: [String: Any] = [:]

    func set(_ value: Any?, forKey defaultName: String) {
        storage[defaultName] = value
    }

    func object(forKey defaultName: String) -> Any? {
        return storage[defaultName]
    }
}
