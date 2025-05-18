//
//  MessageRow.swift
//  ChatGPTClone
//
//  Created by Rish on 17/05/25.
//

import SwiftUI

struct AttributedOutput {
    let string: String
    let results: [ParserResult]
}

enum MessageRowType {
    case attributed(AttributedOutput)
    case rawText(String)
    
    var text: String {
        switch self {
        case .attributed(let attributedOutput):
            return attributedOutput.string
        case .rawText(let string):
            return string
        }
    }
    
    var isEmpty: Bool {
        switch self {
        case .rawText(let t):    return t.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .attributed(let o): return o.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    
    var plainText: String? {
        switch self {
        case .rawText(let t): return t
        case .attributed(let o): return o.string
        }
    }
}

struct MessageRow: Identifiable {
    
    var id = UUID()
    
    var isInteracting: Bool
    
    var send: MessageRowType
    var sendText: String {
        send.text
    }
    
    var response: MessageRowType?
    var responseText: String? {
        response?.text
    }
    
    var responseError: String?
    
}
