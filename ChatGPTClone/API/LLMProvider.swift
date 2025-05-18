//
//  LLMProvider.swift
//  ChatGPTClone
//
//  Created by Rish on 17/05/25.
//

import Foundation

enum LLMProvider: Identifiable, CaseIterable {
    
    case openAI
    
    var id: Self { self }
    
    var text: String {
        switch self {
        case .openAI:
            return "OpenAI"
        }
    }
}
