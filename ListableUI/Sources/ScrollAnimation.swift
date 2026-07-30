//
//  ScrollAnimation.swift
//  ListableUI
//

import UIKit


/// Specifies how a list animates when it is asked to scroll programmatically.
///
/// `UIScrollView` provides no way to control the duration of its built-in content
/// offset animation, so `.system` always runs at a fixed speed. Use `.duration(_:)`
/// when the scroll needs to take a specific amount of time — for example when the
/// scroll paces a sequence of steps the user is being walked through, and the
/// system speed is too fast or too slow to follow.
///
/// Animations are suppressed entirely while `UIView.areAnimationsEnabled` is
/// `false`, matching how the list treats an `animated` flag.
///
public struct ScrollAnimation : Equatable {

    enum Storage : Equatable {
        case none
        case system
        case duration(TimeInterval)
    }

    let storage: Storage

    /// The content offset changes immediately, without animating.
    public static let none = ScrollAnimation(storage: .none)

    /// The content offset changes using `UIScrollView`'s built-in animation.
    ///
    /// The speed of this animation is determined by UIKit and cannot be configured.
    public static let system = ScrollAnimation(storage: .system)

    /// The content offset changes over the provided duration, eased in and out.
    ///
    /// - Parameter duration: How long the scroll should take. A duration of zero or less
    ///   is treated as `.none`.
    public static func duration(_ duration: TimeInterval) -> ScrollAnimation {
        guard duration > 0 else { return .none }

        return ScrollAnimation(storage: .duration(duration))
    }

    /// Ands the animation with the provided bool, returning the animation if true, and `.none` if false.
    public func and(with animated : Bool) -> ScrollAnimation {
        if animated {
            return self
        } else {
            return .none
        }
    }

    /// The animation to actually perform, accounting for whether animations are
    /// currently enabled. A caller inside a `UIView.performWithoutAnimation` block
    /// expects no animation, regardless of what this value describes.
    ///
    /// This has to be evaluated where the scroll is *requested*, not where the content
    /// offset ends up changing. A scroll toward content that has not been laid out yet is
    /// deferred until the presentation state catches up, and that deferred work runs on a
    /// later runloop pass — outside the caller's `performWithoutAnimation` block, where
    /// animations read as enabled again. Resolving late would silently ignore the
    /// caller's request not to animate.
    func resolvedForCurrentContext() -> ScrollAnimation {
        and(with: UIView.areAnimationsEnabled)
    }

    /// Whether the scroll view should run its own animation. A `.duration` animation
    /// drives the content offset itself, so it asks for an unanimated change.
    var usesSystemAnimation: Bool {
        if case .system = storage { return true } else { return false }
    }
}


extension ScrollAnimation {

    /// Creates an animation equivalent to the list's `animated` flag.
    init(animated: Bool) {
        self = .system.and(with: animated)
    }
}
