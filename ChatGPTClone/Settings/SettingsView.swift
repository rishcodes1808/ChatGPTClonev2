//
//  SettingsView.swift
//  ChatGPTClone
//
//  Created by Rish on 17/05/25.
//

import SwiftUI

struct SettingsView: View {
    @StateObject var viewModel = SettingsViewModel()
    
    // Adaptive two-column grid
    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Select Voice")) {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(VoiceType.allCases, id: \.self) { voice in
                            Button(action: {
                                viewModel.selectedVoice = voice
                            }) {
                                Text(voice.rawValue)
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(viewModel.selectedVoice == voice
                                                  ? Color.accentColor.opacity(0.2)
                                                  : Color(UIColor.secondarySystemBackground))
                                    )
                                    .foregroundColor(viewModel.selectedVoice == voice
                                                     ? .accentColor
                                                     : .primary)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .listStyle(.insetGrouped)
        }
    }
}


#Preview {
    SettingsView()
}
