//
//  OpenAIModel.swift
//  ChatGPTClone
//
//  Created by Rish on 17/05/25.
//

import Foundation

enum OpenAIModel: String, Identifiable, CaseIterable {
    
    var id: Self { self }
    
    case gpt3Turbo = "gpt-3.5-turbo"
    case gpt4 = "gpt-4"
    
    var text: String {
        switch self {
        case .gpt3Turbo:
            return "GPT-3.5"
        case .gpt4:
            return "GPT-4"
        }
    }
}
