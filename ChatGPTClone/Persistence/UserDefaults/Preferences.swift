//
//  Preferences.swift
//  ChatGPTClone
//
//  Created by Rish on 17/05/25.
//

import Foundation
import Combine
import SwiftUICore

class Preferences {
    private static func getUserDefaults() -> UserDefaults {
        return UserDefaults.standard
    }
    
    static var standard = Preferences(userDefaults: getUserDefaults())
    let userDefaults: UserDefaultsProtocol
    
    /// Sends through the changed key path whenever a change occurs.
    var preferencesChangedSubject = PassthroughSubject<AnyKeyPath, Never>()
    
    init(userDefaults: UserDefaultsProtocol) {
        self.userDefaults = userDefaults
    }
    
    @UserDefault(.voiceType)
    var selectedVoice: VoiceType = .alloy
}

final class PublisherObservableObject: ObservableObject {
    var subscriber: AnyCancellable?

    init(publisher: AnyPublisher<Void, Never>) {
        self.subscriber = publisher.sink(receiveValue: { [weak self] _ in
            self?.objectWillChange.send()
        })
    }
}

@propertyWrapper
struct Preference<Value>: DynamicProperty {
    @ObservedObject private var preferencesObserver: PublisherObservableObject
    private let keyPath: ReferenceWritableKeyPath<Preferences, Value>
    private let preferences: Preferences

    init(_ keyPath: ReferenceWritableKeyPath<Preferences, Value>, preferences: Preferences = .standard) {
        self.keyPath = keyPath
        self.preferences = preferences
        let publisher = preferences.preferencesChangedSubject
            .filter { changedKeyPath in
                changedKeyPath == keyPath
            }
            .map { _ in () }
            .eraseToAnyPublisher()
        self.preferencesObserver = PublisherObservableObject(publisher: publisher)
    }

    var wrappedValue: Value {
        get { preferences[keyPath: keyPath] }
        nonmutating set { preferences[keyPath: keyPath] = newValue }
    }

    var projectedValue: Binding<Value> {
        Binding(get: { wrappedValue }, set: { wrappedValue = $0 })
    }
}

@propertyWrapper
struct UserDefault<Value: Codable> {
    let key: PreferenceKey
    let defaultValue: Value
    var container: UserDefaults = .standard

    var wrappedValue: Value {
        get { fatalError("Wrapped value should not be used.") }
        set { fatalError("Wrapped value should not be used.") }
    }

    init(wrappedValue: Value, _ key: PreferenceKey) {
        self.defaultValue = wrappedValue
        self.key = key
    }

    public static subscript(
        _enclosingInstance instance: Preferences,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<Preferences, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<Preferences, Self>
    ) -> Value {
        get {
            let container = instance.userDefaults
            let keyString = instance[keyPath: storageKeyPath].key.rawValue
            let defaultValue = instance[keyPath: storageKeyPath].defaultValue
            guard let data = container.object(forKey: keyString) as? Data else { return defaultValue }
            let value = try? JSONDecoder().decode(Value.self, from: data)
            return value ?? defaultValue
        }
        set {
            let container = instance.userDefaults
            let keyString = instance[keyPath: storageKeyPath].key.rawValue
            let data = try? JSONEncoder().encode(newValue)
            container.set(data, forKey: keyString)
            instance.preferencesChangedSubject.send(wrappedKeyPath)
        }
    }
}
