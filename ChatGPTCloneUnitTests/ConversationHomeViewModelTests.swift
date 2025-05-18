//
//  ConversationHomeViewModelTests.swift
//  ChatGPTClone
//
//  Created by Rish on 18/05/25.
//

import XCTest
import AVFoundation
@testable import ChatGPTClone

final class ConversationHomeViewModelTests: XCTestCase {
    var vm: ConversationHomeViewModel!

    override func setUp() {
        super.setUp()
        vm = ConversationHomeViewModel(api: MockLLMClient())
    }

    override func tearDown() {
        vm = nil
        super.tearDown()
    }

    @MainActor func testStartNewConversation() {
        XCTAssertNil(vm.conversationID)
        vm.startNewConversation()
        XCTAssertNotNil(vm.conversationID)
        
        // calling again replaces with a new one
        let first = vm.conversationID
        vm.startNewConversation()
        XCTAssertNotEqual(vm.conversationID, first)
    }
    
    @MainActor func testClearMessages() {
        vm.messages = [
          MessageRow(isInteracting: false,
                     send: .rawText("A"),
                     response: .rawText("B"),
                     responseError: nil)
        ]
        XCTAssertFalse(vm.messages.isEmpty)
        vm.clearMessages()
        XCTAssertTrue(vm.messages.isEmpty)
    }

    func testCancelStreamingResponse() {
        vm.task = Task { }
        XCTAssertNotNil(vm.task)
        vm.cancelStreamingResponse()
        XCTAssertNil(vm.task)
    }

    @MainActor
    func testAudioPlayerDidFinishPlaying_clearsCurrentlyPlaying() async {
        let id = UUID()
        vm.currentlyPlayingMessageID = id
        vm.audioPlayerDidFinishPlaying(AVAudioPlayer(), successfully: true)
        try? await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertNil(vm.currentlyPlayingMessageID)
    }
}
