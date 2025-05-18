//
//  VoiceChatState.swift
//  ChatGPTClone
//
//  Created by Rish on 17/05/25.
//

import Foundation

enum VoiceChatState: Equatable {
    
    var isError: Bool {
        switch self {
        case .error:
            return true
        default:
            return false
        }
    }
    
    case idle
    case recordingSpeech
    case processingSpeech
    case playingSpeech
    case error(String)
}
