//
//  SettingsViewModel.swift
//  ChatGPTClone
//
//  Created by Rish on 17/05/25.
//

import SwiftUI
import Combine

class SettingsViewModel: ObservableObject {
    @Preference(\.selectedVoice) private var selectedVoicePref
    
    @Published var selectedVoice: VoiceType = .alloy {
        didSet {
            selectedVoicePref = selectedVoice
        }
    }
    
    init() {
        self.selectedVoice = selectedVoicePref
    }
}
