//
//  ParserResult.swift
//  ChatGPTClone
//
//  Created by Rish on 17/05/25.
//

import Foundation

struct ParserResult: Identifiable {
    
    var id = UUID()
    let attributedString: AttributedString
    let isCodeBlock: Bool
    let codeBlockLanguage: String?
    
}
