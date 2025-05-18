//
//  KeyboardDismissal.swift
//  ChatGPTClone
//
//  Created by Rish on 17/05/25.
//

import SwiftUI

public class KeyboardDismissal {
    public static func dismissKeyboardFunction() {
        let keyWindow = UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .map { $0 as? UIWindowScene }
            .compactMap { $0 }
            .first?.windows
            .filter { $0.isKeyWindow }.first

        keyWindow?.endEditing(true)
    }
    
    public static func resignFirstResponder() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct DragToDismissViewModifier: ViewModifier {
    var isActive: Bool
    
    @State private var isKeyboardVisible = false
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.height < -5, isActive {
                            KeyboardDismissal.dismissKeyboardFunction()
                        }
                    }
                ,including: isKeyboardVisible ? .all : .subviews
            )
            .onReceive(
                NotificationCenter.default.publisher(for: UIApplication.keyboardWillShowNotification)
            ) { _ in
                isKeyboardVisible = true
            }
            .onReceive(
                NotificationCenter.default.publisher(for: UIApplication.keyboardDidHideNotification)
            ) { _ in
                isKeyboardVisible = false
                
            }
    }
}

public extension View {
    func dismissKeyboardOnDrag(isActive: Bool = true) -> some View {
        self.modifier(DragToDismissViewModifier(isActive: isActive))
    }
}

/// Use this to hide the keyboard on any screen with a tap gesture
struct DismissKeyboard: ViewModifier {
    var isActive: Bool
    func body(content: Content) -> some View {
        if isActive {
            content
                .onTapGesture {
                    KeyboardDismissal.dismissKeyboardFunction()
                }
        } else {
            content
        }
    }
}

public extension View {
    func tapToDismissKeyboard(isActive: Bool = true) -> some View {
        modifier(DismissKeyboard(isActive: isActive))
    }
}
