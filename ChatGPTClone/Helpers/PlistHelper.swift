//
//  PlistHelper.swift
//  ChatGPTClone
//
//  Created by Rish on 18/05/25.
//

import Foundation

public enum PlistHelper {
    public enum Key: String {
        case openAIKey = "OpenAI_API_KEY"
    }

    public static func infoForKey(_ key: Key) -> String {
        guard let value = (Bundle.main.infoDictionary?[key.rawValue] as? String)?
            .replacingOccurrences(of: "\\", with: "") else {
            fatalError("unable to find \(key)")
        }
        return value
    }
}


var openAIKey = PlistHelper.infoForKey(.openAIKey)
