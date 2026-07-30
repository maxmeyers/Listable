//
//  ScrollAnimationDriver.swift
//  ListableUI
//

import UIKit


/// Moves a scroll view's `contentOffset` from where it is to a target offset over a fixed
/// duration, one frame at a time.
///
/// Animating `contentOffset` inside a `UIView` animation block does not work, even though
/// it appears to: the offset lands on its target immediately, so the scroll view lays out
/// its content there and recycles everything it was showing before. Only the layer's
/// bounds animate back to where the scroll started, over a region that no longer has any
/// content in it — the scroll is smooth, but blank.
///
/// Assigning `contentOffset` on every frame is what `UIScrollView` does for its own
/// animation, and it drives the layout passes that keep content on screen throughout.
final class ScrollAnimationDriver {

    private weak var scrollView: UIScrollView?

    private let startOffset: CGPoint
    private let targetOffset: CGPoint
    private let duration: TimeInterval
    private let completion: () -> Void

    private let displayLinkTarget = DisplayLinkTarget()

    private var displayLink: CADisplayLink?
    private var startTimestamp: CFTimeInterval?
    private var hasStarted = false

    init(
        scrollView: UIScrollView,
        from startOffset: CGPoint,
        to targetOffset: CGPoint,
        duration: TimeInterval,
        completion: @escaping () -> Void
    ) {
        self.scrollView = scrollView
        self.startOffset = startOffset
        self.targetOffset = targetOffset
        self.duration = duration
        self.completion = completion

        displayLinkTarget.driver = self
    }

    deinit {
        displayLink?.invalidate()
    }

    /// Begins animating. The scroll view's content offset is expected to already be at
    /// `startOffset`, so the first offset this applies is on the frame after the one the
    /// scroll was requested during.
    ///
    /// A driver animates once and is then spent; starting it again does nothing. Restarting
    /// could not do the right thing anyway, since `startOffset` was captured at init and the
    /// content has since moved away from it.
    func start() {
        guard hasStarted == false else {
            assertionFailure("A scroll animation cannot be started twice.")
            return
        }

        hasStarted = true

        let displayLink = CADisplayLink(
            target: displayLinkTarget,
            selector: #selector(DisplayLinkTarget.tick)
        )

        displayLink.add(to: .main, forMode: .common)

        self.displayLink = displayLink
    }

    /// Stops the animation where it is, leaving the content offset untouched, and reports
    /// its completion.
    func cancel() {
        guard displayLink != nil else { return }

        finish()
    }

    fileprivate func tick(_ displayLink: CADisplayLink) {
        guard let scrollView else {
            finish()
            return
        }

        // The first tick lands a frame's worth of time after the animation began, so it
        // establishes the clock rather than advancing it. Advancing here instead would
        // skip the start of the animation.
        guard let startTimestamp else {
            startTimestamp = displayLink.timestamp
            return
        }

        let elapsed = displayLink.timestamp - startTimestamp

        guard elapsed < duration else {
            scrollView.setContentOffset(targetOffset, animated: false)
            finish()
            return
        }

        let progress = Self.eased(elapsed / duration)

        scrollView.setContentOffset(
            CGPoint(
                x: startOffset.x + (targetOffset.x - startOffset.x) * progress,
                y: startOffset.y + (targetOffset.y - startOffset.y) * progress
            ),
            animated: false
        )
    }

    private func finish() {
        displayLink?.invalidate()
        displayLink = nil

        completion()
    }

    /// `UIScrollView` eases its own animation in and out, and so does this. This curve stays
    /// within ~2% of UIKit's `.curveEaseInOut`, which cannot be evaluated directly — a
    /// `CAMediaTimingFunction` only exposes its control points, not the value at a given time.
    private static func eased(_ progress: Double) -> Double {
        (1 - cos(.pi * progress)) / 2
    }
}


/// `CADisplayLink` retains its target and the runloop retains the link, so a driver that
/// targeted itself could not be deallocated while its animation was in flight — its
/// `deinit` would never run to invalidate the link. Targeting this instead keeps the only
/// reference back to the driver a weak one.
private final class DisplayLinkTarget {

    weak var driver: ScrollAnimationDriver?

    @objc func tick(_ displayLink: CADisplayLink) {
        driver?.tick(displayLink)
    }
}
