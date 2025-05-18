//
//  Shimmer.swift
//  ChatGPTClone
//
//  Created by Rish on 17/05/25.
//

import SwiftUI

/// A view modifier that applies an animated "shimmer" to any view.
public struct ShimmerEffect: ViewModifier {
    private let animation: Animation
    private let gradient: Gradient
    private let min, max: CGFloat
    private let bandSize: CGFloat
    @State private var isShimmering: Bool = false

    /// Initializes the shimmer effect.
    /// - Parameters:
    ///   - animation: The animation to use for the shimmer. Defaults to a linear animation.
    ///   - gradient: The gradient to use for the shimmer. Defaults to a standard shimmer gradient.
    ///   - bandSize: The size of the animated mask's "band". Defaults to 0.3 (30% of the view's width).
    public init(
        animation: Animation = Self.defaultAnimation,
        gradient: Gradient = Self.defaultGradient,
        bandSize: CGFloat = 0.3
    ) {
        self.animation = animation
        self.gradient = gradient
        // Calculate the start and end points for the gradient animation
        self.min = 0 - bandSize
        self.max = 1 + bandSize
        self.bandSize = bandSize
    }

    /// The default animation for the shimmer effect.
    public static let defaultAnimation = Animation.linear(duration: 1.5).delay(0.25).repeatForever(autoreverses: false)

    /// The default gradient for the shimmer effect.
    public static let defaultGradient = Gradient(colors: [
        .black.opacity(0.3), // Less visible
        .black,             // More visible (peak of the shimmer)
        .black.opacity(0.3) // Less visible
    ])

    public func body(content: Content) -> some View {
        content
            .mask(
                LinearGradient(
                    gradient: gradient,
                    startPoint: UnitPoint(x: isShimmering ? max : min, y: 0.5), // Animate horizontally
                    endPoint: UnitPoint(x: isShimmering ? max + bandSize : min + bandSize, y: 0.5)
                )
                .animation(animation, value: isShimmering)
            )
            .onAppear {
                // Start the animation shortly after the view appears
                // DispatchQueue helps to ensure layout is complete before starting.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                     isShimmering = true
                }
            }
    }
}

public extension View {
    /// Adds an animated shimmering effect to the view.
    /// - Parameters:
    ///   - active: A boolean to control whether the shimmer effect is active. Defaults to `true`.
    ///   - animation: The animation to use for the shimmer.
    ///   - gradient: The gradient to use for the shimmer.
    ///   - bandSize: The size of the animated mask's "band".
    /// - Returns: A view with the shimmering effect applied.
    @ViewBuilder func shimmering(
        active: Bool = true,
        animation: Animation = ShimmerEffect.defaultAnimation,
        gradient: Gradient = ShimmerEffect.defaultGradient,
        bandSize: CGFloat = 0.3
    ) -> some View {
        if active {
            modifier(ShimmerEffect(animation: animation, gradient: gradient, bandSize: bandSize))
        } else {
            self
        }
    }
}
