//
//  ConversationHomeView.swift
//  ChatGPTClone
//
//  Created by Rish on 17/05/25.
//

import SwiftUI
import AVKit

struct ConversationHomeView: View {
        
    @Environment(\.colorScheme) var colorScheme
    @StateObject var vm = ConversationHomeViewModel(api: OpenAIAPI(apiKey: ""))
    @FocusState var isTextFieldFocused: Bool
    @State private var showVoiceInputView = false
    
    @State private var toastText: String? = nil
    @EnvironmentObject var networkMonitor: NetworkMonitor
    
    var body: some View {
        NavigationStack {
            chatListView
                .tapToDismissKeyboard()
                .navigationTitle("Jump Chat \(vm.isVoiceConversation ? "(Voice)" : "")")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        NavigationLink {
                            ConversationHistoryView(onNewConversation: {
                                vm.startNewConversation()
                            }, onSelect: { conversation in
                                vm.loadConversation(conversation: conversation)
                            })
                        } label: {
                            Image(systemName: "list.bullet")
                                .imageScale(.large)
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink {
                            SettingsView()
                        } label: {
                            Image(systemName: "gearshape")
                                .imageScale(.large)
                        }
                    }
                }
                .fullScreenCover(isPresented: $showVoiceInputView) {
                    VoiceConversationView()
                }
        }
        .overlay(
            Group {
                if let toastText = toastText, !toastText.isEmpty {
                    ToastView(text: toastText)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .padding(.top, 30)
                }
            },
            alignment: .top
        )
    }
    
    var chatListView: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        Spacer()
                            .frame(height: 12)
                        ForEach(vm.messages) { message in
                            MessageRowView(
                                message: message,
                                isPlaying: vm.currentlyPlayingMessageID == message.id,
                                retryCallback: { row in
                                    Task { @MainActor in
                                        await vm.retry(message: row)
                                    }
                                }, onShowToast: { text in
                                    withAnimation {
                                        toastText = text
                                    }
                                    hideToast()
                                }, onPlay: {
                                    if networkMonitor.isOffline {
                                        withAnimation {
                                            toastText = "You are offline. Please connect to the internet and try again."
                                        }
                                        hideToast()
                                    } else {
                                        vm.playResponse($0)
                                    }
                                })
                        }
                        .padding(.bottom, 12)
                    }
                    .onTapGesture {
                        isTextFieldFocused = false
                    }
                }
                
                Divider()
                bottomView(proxy: proxy)
                Spacer()
            }
            .onChange(of: vm.messages.last?.responseText) { _, _ in  scrollToBottom(proxy: proxy) }
        }
        .background(Color.primaryBackground)
    }
    
    func bottomView(proxy: ScrollViewProxy) -> some View {
        HStack(alignment: .top, spacing: 8) {
            TextField("Send message", text: $vm.inputMessage, axis: .vertical)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)
                .focused($isTextFieldFocused)
                .disabled(vm.isInteracting)
            
            if vm.isInteracting {
                Button {
                    vm.cancelStreamingResponse()
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 30))
                        .symbolRenderingMode(.multicolor)
                        .foregroundColor(.red)
                }
            } else {
                Button {
                    Task { @MainActor in
                        isTextFieldFocused = false
                        scrollToBottom(proxy: proxy)
                        await vm.sendTapped()
                    }
                } label: {
                    Image(systemName: "paperplane.circle.fill")
                        .rotationEffect(.degrees(45))
                        .font(.system(size: 30))
                }
                .disabled(vm.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            Button(action: {
                showVoiceInputView = true
            }) {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 30))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let id = vm.messages.last?.id else { return }
        proxy.scrollTo(id, anchor: .bottomTrailing)
    }
    
    private func hideToast() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { toastText = nil }
        }
    }
}


#Preview {
    NavigationStack {
        ConversationHomeView(vm: ConversationHomeViewModel(api: OpenAIAPI(apiKey: "")))
    }
}

