//
//  VoiceConversationViewModelTests.swift
//  ChatGPTClone
//
//  Created by Rish on 18/05/25.
//

import XCTest
@testable import ChatGPTClone
import AVFoundation

final class VoiceConversationViewModelTests: XCTestCase {

    var vm: VoiceConversationViewModel!

    override func setUp() {
        super.setUp()
        vm = VoiceConversationViewModel()
    }

    override func tearDown() {
        vm = nil
        super.tearDown()
    }

    // MARK: - Conversation Lifecycle

    func testStartNewConversation_setsNonNilID() {
        XCTAssertNil(vm.conversationID)
        vm.startNewConversation()
        XCTAssertNotNil(vm.conversationID)
    }

    func testStartNewConversation_generatesDifferentIDs() {
        vm.startNewConversation()
        let first = vm.conversationID
        vm.startNewConversation()
        let second = vm.conversationID
        XCTAssertNotEqual(first, second)
    }

    // MARK: - State Helpers

    func testIsIdle_whenStateIsIdle_true() {
        vm.state = .idle
        XCTAssertTrue(vm.isIdle)
    }
    func testIsIdle_whenStateIsRecording_false() {
        vm.state = .recordingSpeech
        XCTAssertFalse(vm.isIdle)
    }
    func testIsIdle_whenStateIsProcessing_false() {
        vm.state = .processingSpeech
        XCTAssertFalse(vm.isIdle)
    }
    func testIsIdle_whenStateIsPlaying_false() {
        vm.state = .playingSpeech
        XCTAssertFalse(vm.isIdle)
    }

    // MARK: - Permission Flow

    func testOnAppear_deniedPermission_updatesState() {
        let expectation = self.expectation(description: "denial")
        vm.state = .idle

        AVAudioApplication.requestRecordPermission { _ in }

        vm.state = .error("Recording not allowed by the user")
        vm.userDeniedMicrophonePermission = true

        XCTAssertEqual(vm.state, .error("Recording not allowed by the user"))
        XCTAssertTrue(vm.userDeniedMicrophonePermission)
        expectation.fulfill()

        waitForExpectations(timeout: 0.1)
    }
}
