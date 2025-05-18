//
//  HapticsManager.swift
//  ChatGPTClone
//
//  Created by Rish on 17/05/25.
//

import CoreHaptics
import SwiftUI


public class HapticsManager: ObservableObject {
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private var impactGenerator: UIImpactFeedbackGenerator?

    static let shared = HapticsManager()

    private init() {}

    func notificationOccured(style: UINotificationFeedbackGenerator.FeedbackType) {
        notificationGenerator.notificationOccurred(style)
    }

    func impactOccured(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        impactGenerator = UIImpactFeedbackGenerator(style: style)
        impactGenerator?.impactOccurred()
    }
    
    public static func lightFeedback() {
        HapticsManager.shared.impactOccured(style: .light)
    }
    
    public static func strongFeedback() {
        HapticsManager.shared.impactOccured(style: .medium)
    }
}
