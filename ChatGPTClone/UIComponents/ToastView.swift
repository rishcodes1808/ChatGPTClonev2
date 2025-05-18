//
//  ToastView.swift
//  ChatGPTClone
//
//  Created by Rish on 17/05/25.
//

import SwiftUI

struct ToastView: View {
    let text: String

    var body: some View {
        Text(text)
            .multilineTextAlignment(.center)
            .font(.subheadline.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 30)
            .padding(.vertical, 20)
            .background(Capsule().fill(Color.black.opacity(0.8)))
    }
}
