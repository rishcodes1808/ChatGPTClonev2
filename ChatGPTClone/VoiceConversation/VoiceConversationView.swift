//
//  VoiceConversationView.swift
//  ChatGPTClone
//
//  Created by Rish on 17/05/25.
//

import SwiftUI

struct VoiceConversationView: View {
    
    @StateObject var vm = VoiceConversationViewModel()
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var networkMonitor: NetworkMonitor

    var body: some View {
        NavigationStack {
            ZStack {
                Color.primaryBackground
                    .ignoresSafeArea()

                if networkMonitor.isOffline {
                    offlineView
                }
                else if vm.userDeniedMicrophonePermission {
                    micDeniedView
                }
                else {
                    mainVoiceChatView
                }
            }
            .navigationTitle("Voice Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        vm.cancelRecording()
                        vm.cancelProcessingTask()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .onAppear {
                vm.startNewConversation()
                vm.onAppear()
                if vm.state == .idle || vm.state.isError {
                    vm.startCaptureAudio()
                }
            }
            .onDisappear {
                vm.cancelRecording()
                vm.cancelProcessingTask()
            }
        }
    }

    private var offlineView: some View {
        VStack(spacing: 24) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("No Internet Connection")
                .font(.title2).bold()

            Text("Please check your network settings and try again.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Button("Retry") {
                if !networkMonitor.isOffline {
                    vm.startCaptureAudio()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var micDeniedView: some View {
        VStack(spacing: 24) {
            Image(systemName: "mic.slash.circle")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("Microphone Access Denied")
                .font(.title2).bold()

            Text("Please enable microphone access in Settings to use voice chat.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: – Main Voice-Chat UI
    private var mainVoiceChatView: some View {
        VStack(spacing: 16) {
            Spacer()

            VoiceVisualizerView(viewModel: vm)
                .frame(height: 256)

            Spacer()

            if case let .error(err) = vm.state {
                Text(err.localizedDescription)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
    }
}

#Preview("Offline") {
    VoiceConversationView()
        .environmentObject(NetworkMonitor.shared)
}

#Preview("Mic Denied") {
    let vm = VoiceConversationViewModel()
    vm.userDeniedMicrophonePermission = true
    return VoiceConversationView(vm: vm)
        .environmentObject(NetworkMonitor.shared)
}

#Preview("Normal") {
    VoiceConversationView()
        .environmentObject(NetworkMonitor.shared)
}
