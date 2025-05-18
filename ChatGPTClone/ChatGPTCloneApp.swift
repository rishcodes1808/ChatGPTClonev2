//
//  ChatGPTCloneApp.swift
//  ChatGPTClone
//
//  Created by Rish on 16/05/25.
//

import SwiftUI

@main
struct ChatGPTCloneApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared

    var body: some Scene {
        WindowGroup {
            ConversationHomeView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(networkMonitor)
        }
    }
}
