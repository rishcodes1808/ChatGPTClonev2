//
//  ChatBubble.swift
//  ChatGPTClone
//
//  Created by Rish on 17/05/25.
//

import SwiftUI
import Markdown

struct ChatBubble: Shape {
    var isUser: Bool

    func path(in r: CGRect) -> Path {
        let corner: CGFloat = 16
        let tailSize: CGFloat = 8
        var p = Path()

        let rect = CGRect(
            x: r.minX + (isUser ? 0 : tailSize),
            y: r.minY,
            width: r.width - tailSize,
            height: r.height
        )
        p.addRoundedRect(
            in: rect,
            cornerSize: CGSize(width: corner, height: corner)
        )

        return p
    }
}
