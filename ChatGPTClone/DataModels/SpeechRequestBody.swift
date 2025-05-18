//
//  SpeechRequestBody.swift
//  ChatGPTClone
//
//  Created by Rish on 17/05/25.
//

import Foundation

struct SpeechRequestBody: Encodable {
    let model: String
    let input: String
    let voice: String
}
