//
//  XCSegmentable.swift
//  XCSegmentable
//
//  Created by SAGESSE on 2019/6/11.
//  Copyright © 2019 SAGESSE. All rights reserved.
//

import UIKit


public protocol XCSegmentable: class {
    
    /// Configure the vertical segmented managing view.
    var segmenting: XCSegmentingView { get }

}

public extension XCSegmentable where Self: UIView {
    
    /// Configure the vertical segmented managing view.
    var segmenting: XCSegmentingView {
        
        // If already created, reuse it.
        if let fsObject = objc_getAssociatedObject(self, &XCSegmentingView.defaultKey) as? XCSegmentingView {
            return fsObject
        }
        
        // Create a new implementation object.
        let fsObject = XCSegmentingView(embed: self)
        objc_setAssociatedObject(self, &XCSegmentingView.defaultKey, fsObject, .OBJC_ASSOCIATION_RETAIN)
        return fsObject
    }
    
}
public extension XCSegmentable where Self: UIViewController {

    /// Configure the vertical segmented managing view.
    var segmenting: XCSegmentingView {
        
        // If already created, reuse it.
        if let fsObject = objc_getAssociatedObject(self, &XCSegmentingView.defaultKey) as? XCSegmentingView {
            return fsObject
        }
        
        // Create a new implementation object.
        let fsObject = XCSegmentingView(embed: self)
        objc_setAssociatedObject(self, &XCSegmentingView.defaultKey, fsObject, .OBJC_ASSOCIATION_RETAIN)
        return fsObject
    }

}


@objc
open class XCSegmentingView: UIView, UIGestureRecognizerDelegate {
    
    
    /// Create a container view with embed view.
    public convenience init(embed view: UIView) {
        // Call the common init method.
        self.init()
        self.viewController = nil
        self.updateSuperview(view)
    }
    
    /// Create a container view with embed view controller.
    public convenience init(embed viewController: UIViewController) {
        // Call the common init method.
        self.init()
        self.viewController = viewController
        self.hasViewController = true
        
        // Observer for any change for self.view.
        // Can't specify initial option, it causes self.view to load early.
        self.viewController?.addObserver(self, forKeyPath: "view", options: .new, context: .init(mutating: sel_getName(#selector(updateSuperviewWithObserver(_:)))))
        
        // Automatic remove observer when view controller dealloc.
        self.viewController?.addDestructObserver { [weak self] in
            self.map {
                // The view controller is release before the container view, required manual cleanup of observer.
                $0.viewController?.removeObserver($0, forKeyPath: "view")
                $0.viewController = nil
            }
        }

        // If the view has been loaded, call the update manually.
        if self.viewController?.isViewLoaded ?? false {
            self.updateSuperviewWithObserver(viewController)
        }
    }

    
    /// Configure the header view.
    open var headerView: UIView? {
        willSet {
            updateSubview(forHeaderView: newValue)
        }
    }
    
    /// Configure the content view.
    open var contentView: UIView? {
        willSet {
            updateSubview(forContentView: newValue)
        }
    }
    
    /// Configure the footer view.
    open var footerView: UIView? {
        willSet {
            updateSubview(forFooterView: newValue)
        }
    }
    
    /// Configure the presented view.
    open var presentedView: UIVisualEffectView {
        return presentingView
    }


    /// Configure the height of each level.
    open var levels: Array<CGFloat> {
        set {
            // The levels must to change for update.
            guard newValue != orderedLevels, !newValue.isEmpty else {
                return
            }
            
            // Compute level with intrinsic size.
            let height = intrinsicLayoutConstraint.constant
            let level = orderedLevels.firstIndex(where: { height <= $0 }) ?? orderedLevels.count - 1
            
            // Apply new level.
            updateContentSize(newValue[max(min(level, newValue.count - 1), 0)])
            
            // Update level.
            orderedLevels = newValue
        }
        get {
            return orderedLevels
        }
    }
    
    /// Show with specified level.
    open func setLevel(_ level: CGFloat, animated: Bool) {
        // Just update the height.
        return updateContentSize(closest(at: level, velocity: 0), velocity: .zero, animated: animated)
    }
    

    /// Automatically perform to the specified method for context.
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        context.map {
            _ = perform(sel_registerName($0.assumingMemoryBound(to: Int8.self)), with: object, with: change)
        }
    }

    /// Check the gestures recognizer are allows to be activate.
    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        // Only needs to do is process the drag gesture recognizer.
        guard !(trackingView?.isTracking ?? false), let view = headerView, gestureRecognizer === dragGestureRecognizer else {
            return false
        }
        
        // The gesture recognizer valid in inside only the header view.
        return view.bounds.contains(touch.location(in: view))
    }
    
    /// Check the gestures recognizer are allows to be simultaneous activate.
    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        // Only needs to do is process the drag gesture recognizer.
        guard gestureRecognizer === dragGestureRecognizer, otherGestureRecognizer is UIPanGestureRecognizer else {
            return false
        }
        
        // The gesture recognizer must include the view information.
        guard let view = gestureRecognizer.view, let subview = otherGestureRecognizer.view else {
            return false
        }
        
        return subview.isDescendant(of: view)
    }


    fileprivate func updateContentSize(_ height: CGFloat) {
        
        // The UI is really updated when the height is has change.
        guard intrinsicLayoutConstraint.constant != height else {
            return
        }

        // Apply the intrinsic content size change.
        intrinsicLayoutConstraint.constant = height
        
        // Apply the visibility with new intrinsic content size.
        updateContentVisibility(height)
    }
    fileprivate func updateContentSize(_ height: CGFloat, velocity: CGPoint, animated: Bool) {
        
        // Add animation only if changes have been made.
        guard height != intrinsicLayoutConstraint.constant else {
            return
        }
        
        // If no need animation, directly update the layout view.
        guard animated else {
            // Layout subviews.
            self.updateContentSize(height)
            self.setNeedsLayout()
            self.superview?.layoutIfNeeded()
            return
        }
        
        // Compute initial velocity.
        let initialVelocity = -velocity.y / (height - intrinsicLayoutConstraint.constant) // 2
        
        var stiffness: CGFloat = 312.11
        var damping: CGFloat = 31.96
        var duration: TimeInterval = 0.35
        
        if initialVelocity > 4 {
            
            stiffness = 471.50
            damping = 30.70
        }
        
        // If the distance is too short, it takes longer to animate.
        if (height - intrinsicLayoutConstraint.constant) < 300 {
            duration = 0.5
        }
        
        if #available(iOS 10.0, *) {
            
            let timeing = UISpringTimingParameters(mass: 1, stiffness: stiffness, damping: damping, initialVelocity: .init(dx: 0, dy: initialVelocity))
            let relayAnimator = UIViewPropertyAnimator(duration: duration, timingParameters: timeing)
            
            relayAnimator.isInterruptible = false
            relayAnimator.addAnimations { [unowned self] in
                // Layout subviews.
                self.updateContentSize(height)
                self.setNeedsLayout()
                self.superview?.layoutIfNeeded()
            }
            relayAnimator.startAnimation()
        } else {
            // Fallback on earlier versions
            UIView.animate(withDuration: duration) {
                self.updateContentSize(height)
                self.setNeedsLayout()
                self.superview?.layoutIfNeeded()
            }
        }
    }
    fileprivate func updateContentSize(_ height: CGFloat, animated: Bool) {
        
        // Calculate the best display content offset.
        let height = closest(at: height, velocity: 0)
        
        // Reset the content offset.
        dragContentOffset.y = height
        dragContentTranslation.y = height

        // Update content size with animation.
        updateContentSize(height, velocity: .zero, animated: animated)
    }
    
    @objc fileprivate func updateContentSizeWithObserver(_ scrollView: UIScrollView, change: [NSKeyValueChangeKey : Any]?) {
        
        // Check the scroll view state are ready.
        guard !isLockedOffsetChanges, scrollView.panGestureRecognizer.state != .possible, dragGestureRecognizer.state == .possible else {
            return
        }
        
        // Don't call the observing method again, prevent recursion.
        isLockedOffsetChanges = true
        defer {
            isLockedOffsetChanges = false
        }
        
        let gestureRecognizer = scrollView.panGestureRecognizer
        switch gestureRecognizer.state {
        case .began:
            
            // If the scroll view state is decelerating, don't tracking.
            guard !scrollView.isDecelerating else {
                return
            }
            
            // Mark the state as begin.
            trackingView = scrollView
            
            // Begin dragging.
            beginDrag(gestureRecognizer.translation(in: nil))
            
        case .changed:
            
            // No begin no chnage.
            guard trackingView != nil else {
                return
            }

            // Calculates the offset of drag action.
            let translation = gestureRecognizer.translation(in: nil)
            
            // If the content offset less zero, must update height prevent overbounary.
            if scrollView.contentOffset.y + scrollView.contentInset.top >= 0 {
                
                // If current height is maximum height, allow free dragging.
                guard let maximum = orderedLevels.last, intrinsicLayoutConstraint.constant < maximum else {
                    dragContentTranslation = translation
                    return
                }
                
                // If the drag is downward, allowes when content offset is not zero
                guard gestureRecognizer.velocity(in: nil).y < 0 else {
                    dragContentTranslation = translation
                    return
                }
            }
            
            // Update dragging.
            updateDrag(gestureRecognizer.translation(in: nil))

            
        case .ended,
             .cancelled,
             .failed:
            
            // No begin no end.
            guard trackingView != nil else {
                return
            }

            // Mark the state as end.
            trackingView = nil
            
            // Animation is required when the height less than the maximum height.
            guard let maximum = orderedLevels.last, intrinsicLayoutConstraint.constant < maximum else {
                return
            }
            
            // End dragging, must use 10 times force.
            endDrag(gestureRecognizer.velocity(in: nil), factor: 0.2)
            
            // If the scroll view still want to swipe, force cancel it.
            if scrollView.isDragging {
                gestureRecognizer.touchesCancelled(.init(), with: .init())
            }
            
        default:
            return
        }
        
        // If it's state change, ignore it.
        var oldVlaue = change?[.oldKey] as? CGPoint ?? scrollView.contentOffset
        
        // Rollback the content offset change.
        oldVlaue.y = max(oldVlaue.y, -scrollView.contentInset.top)
        scrollView.contentOffset = oldVlaue
    }
    @objc fileprivate func updateContentSizeWithRecognizer(_ gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            
            // Try to cancel the content view decelerating aniamtion.
            if let scrollView = contentView as? UIScrollView, scrollView.isDecelerating {
                var newContentOffset = scrollView.contentOffset
                newContentOffset.y = max(newContentOffset.y, -scrollView.contentInset.top)
                scrollView.setContentOffset(newContentOffset, animated: false)
            }
            
            // Begin dragging.
            beginDrag(gestureRecognizer.translation(in: nil))
            
        case .changed:
            
            // Update dragging.
            updateDrag(gestureRecognizer.translation(in: nil))
            
        case .ended,
             .cancelled,
             .failed:
            
            // End dragging.
            endDrag(gestureRecognizer.velocity(in: nil))
            
        default:
            break
        }
    }
    
    fileprivate func updateContentVisibility(_ height: CGFloat) {
        // Might need to compute mutable alpha in iOS 11.
        guard #available(iOS 11.0, *) else {
            return
        }
        
        // Must specified header view and current device is iPhone X series.
        guard let headerView = headerView, safeAreaInsets.bottom != 0 else {
            return
        }
        
        // Compute the mutable alpha of the content view and footer view.
        let offset = height - headerView.frame.height
        let newValue = max(min(offset / safeAreaInsets.bottom, 1), 0)
        
        // Apply alpha to content view and footer view.
        guard visibility != newValue else {
            return
        }
        
        // Apply the mutable alpha.
        visibility = newValue
        footerView?.alpha = newValue
        contentView?.alpha = newValue
    }
    
    fileprivate func updateSubview(forHeaderView newValue: UIView?) {
        // If the new value not any changes, ignore it.
        guard newValue?.superview !== presentingView.contentView else {
            return
        }
        
        // First remove the view to clear the constraint.
        headerView?.removeFromSuperview()
        
        // Second check the header view needs to be re-added.
        guard let newValue = newValue else {
            return
        }
        
        // Configure the header view.
        newValue.translatesAutoresizingMaskIntoConstraints = false
        
        // Add the view to the container view.
        presentingView.contentView.addSubview(newValue)
        
        // Restore header view constraints
        NSLayoutConstraint.activate(
            [
                newValue.topAnchor.constraint(equalTo: topLayoutGuide.topAnchor),
                newValue.leftAnchor.constraint(equalTo: leftAnchor),
                newValue.rightAnchor.constraint(equalTo: rightAnchor),
                newValue.bottomAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor)
            ]
        )
    }
    fileprivate func updateSubview(forContentView newValue: UIView?) {
        // If the new value not any changes, ignore it.
        guard newValue?.superview !== presentingView.contentView else {
            return
        }
        
        // If the old content view is kind of scroll view, must to remove observer first.
        (contentView as? UIScrollView).map {
            
            $0.removeObserver(self, forKeyPath: "panGestureRecognizer.state")
            $0.removeObserver(self, forKeyPath: "contentOffset")
        }
        
        // First remove the view to clear the constraint.
        contentView?.removeFromSuperview()
        
        // Second check the header view needs to be re-added.
        guard let newValue = newValue else {
            return
        }
        
        // Configure the header view.
        newValue.alpha = visibility
        newValue.translatesAutoresizingMaskIntoConstraints = false
        
        // Add the view to the container view.
        presentingView.contentView.addSubview(newValue)
        
        // Restore header view constraints
        NSLayoutConstraint.activate(
            [
                newValue.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
                newValue.leftAnchor.constraint(equalTo: leftAnchor),
                newValue.rightAnchor.constraint(equalTo: rightAnchor),
                newValue.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor)
            ]
        )
        
        // If the new content view is kind of scroll view, must to restore observer.
        (newValue as? UIScrollView).map {
            
            let selector = UnsafeMutableRawPointer(mutating: sel_getName(#selector(updateContentSizeWithObserver(_:change:))))
            
            $0.addObserver(self, forKeyPath: "contentOffset", options: .old, context: selector)
            $0.addObserver(self, forKeyPath: "panGestureRecognizer.state", options: .new, context: selector)
        }
        
        // Update content size and confiure subviews.
        updateContentSize(intrinsicLayoutConstraint.constant)
    }
    fileprivate func updateSubview(forFooterView newValue: UIView?) {
        // If the new value not any changes, ignore it.
        guard newValue?.superview !== presentingView.contentView else {
            return
        }
        
        // First remove the view to clear the constraint.
        footerView?.removeFromSuperview()
        
        // Second check the header view needs to be re-added.
        guard let newValue = newValue else {
            return
        }
        
        // Configure the header view.
        newValue.alpha = visibility
        newValue.translatesAutoresizingMaskIntoConstraints = false
        
        // Add the view to the container view.
        presentingView.contentView.addSubview(newValue)
        
        // The bottom layout constraint is not required, because when the content view or header view
        // specifies the size, the footer view will be over out of the container view boundary.
        let bottomLayoutConstraint = newValue.bottomAnchor.constraint(equalTo: intrinsicLayoutGuide.bottomAnchor)
        bottomLayoutConstraint.priority = .defaultLow - 1
        
        // Restore header view constraints
        NSLayoutConstraint.activate(
            [
                newValue.topAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor),
                newValue.leftAnchor.constraint(equalTo: leftAnchor),
                newValue.rightAnchor.constraint(equalTo: rightAnchor),
                
                bottomLayoutConstraint
            ]
        )
        
        // Update content size and confiure subviews.
        updateContentSize(intrinsicLayoutConstraint.constant)
    }
    
    fileprivate func updateSuperview(_ superview: UIView) {
        
        // If the superview is changes, reattach it.
        guard superview !== self.superview else {
            return
        }
        
        // First remove container view from view controller, so that the constraint is automatically remove.
        removeFromSuperview()
        
        // And then add the container view to view controller.
        superview.addSubview(self)
        
            // Get a bottom constraint that is compatible with iOS 10 and iOS 11+.
        var safeAreaBottomAnchor = superview.bottomAnchor
        if #available(iOS 11.0, *) {
            safeAreaBottomAnchor = superview.safeAreaLayoutGuide.bottomAnchor
        }
        
        // Finally restore the view controller constraints.
        NSLayoutConstraint.activate(
            [
               leftAnchor.constraint(equalTo: superview.leftAnchor),
               widthAnchor.constraint(equalTo: superview.widthAnchor),
               bottomAnchor.constraint(equalTo: superview.bottomAnchor),
               
               // If view controller is not specified, the intrinsic content size bottom aligne to the the superview bottom.
               intrinsicLayoutGuide.bottomAnchor.constraint(equalTo: viewController?.bottomLayoutGuide.topAnchor ?? safeAreaBottomAnchor)
            ]
        )
        
        // Trying to restore subview.
        headerView.map { updateSubview(forHeaderView: $0) }
        contentView.map { updateSubview(forContentView: $0) }
        footerView.map { updateSubview(forHeaderView: $0) }
    }
    @objc fileprivate func updateSuperviewWithObserver(_ viewController: UIViewController) {
        
        // Apply superview for view controller.
        updateSuperview(viewController.view)
    }
    

    @inline(__always) fileprivate func beginDrag(_ translation: CGPoint) {
        
        // Must update offset to the latest state before you can start dragging.
        dragContentOffset.y = intrinsicLayoutConstraint.constant
        dragContentTranslation.y = 0
    }
    @inline(__always) fileprivate func updateDrag(_ translation: CGPoint) {
        
        // Incremental update content offset.
        dragContentOffset.y -= translation.y - dragContentTranslation.y
        dragContentTranslation.y = translation.y
        
        // Update height with aligned content offset.
        updateContentSize(align(dragContentOffset.y))
    }
    @inline(__always) fileprivate func endDrag(_ velocity: CGPoint, factor: CGFloat = 1) {
        
        // Calculate the best display content offset.
        let offset = closest(at: dragContentOffset.y, velocity: velocity.y * factor)
        
        // Reset the content offset.
        dragContentOffset.y = offset
        dragContentTranslation.y = offset
        
        // Add animation only if changes have been made.
        guard offset != intrinsicLayoutConstraint.constant else {
            return
        }
        
        // Update content size with animation.
        updateContentSize(offset, velocity: velocity, animated: true)
    }
    
    @inline(__always) fileprivate func align(_ offset: CGFloat) -> CGFloat {
        
        // Check if the lower bound is exceeded.
        if let minimum = orderedLevels.first, offset < minimum {
            return minimum
        }
        
        // Check if the upper bound is exceeded.
        if let maximum = orderedLevels.last, offset > maximum {
            return maximum + bounces(offset - maximum, maximum: 80)
        }
        
        return offset
    }
    @inline(__always) fileprivate func bounces(_ offset: CGFloat, maximum: CGFloat) -> CGFloat {
        
        // Must need to prevent dividing by 0.
        guard offset != 0 && maximum != 0 else {
            return 0
        }
        
        // Magic number from `Maps.app`
        let scale = CGFloat(0.55)
        
        // https://www.desmos.com/calculator/mvnbadnt8u
        return (offset * scale * maximum) / (offset * scale + maximum)
    }
    
    @inline(__always) fileprivate func closest(at offset: CGFloat, velocity: CGFloat) -> CGFloat {
        
        // If the drag is too small.
        guard abs(velocity) > 50 else {
            // Restore to position on started dragging.
            return growing(at: offset)
        }
        
        // Check the drag direction.
        if velocity < 0 {
            // The direction is up.
            return growing(at: offset - velocity / 100)
        }
        
        // The direction is down.
        return shrinking(at: offset - velocity / 20)
    }
    @inline(__always) fileprivate func growing(at offset: CGFloat) -> CGFloat {
        // Find the most appropriate level.
        return orderedLevels.first { offset <= $0 } ?? orderedLevels.last ?? 0
    }
    @inline(__always) fileprivate func shrinking(at offset: CGFloat) -> CGFloat {
        
        // Check all levels by order
        for level in 0 ..< orderedLevels.count - 1 {
            // Get to the lowest level.
            if offset < orderedLevels[level + 1] {
                return orderedLevels[level]
            }
        }
        
        // Other case always use the highest one.
        return orderedLevels.last ?? 0
    }
    
    
    /// Common init.
    fileprivate init() {
        // Calculate the default height from the screen.
        self.orderedLevels = [
            UIScreen.main.bounds.height * 0.1,
            UIScreen.main.bounds.height * 0.5,
            UIScreen.main.bounds.height * 0.9
        ]
        
        // Create a intrinsic layout constraint.
        self.intrinsicLayoutConstraint = self.intrinsicLayoutGuide.heightAnchor.constraint(equalToConstant: 0)

        // Build base view.
        super.init(frame: CGRect(x: 0, y: 0, width: 375, height: 240))

        // Configure the presenting view.
        self.presentingView.bounds = self.bounds
        self.presentingView.isOpaque = true
        self.presentingView.clipsToBounds = false
        self.presentingView.backgroundColor = nil
        self.presentingView.translatesAutoresizingMaskIntoConstraints = false
        self.presentingView.contentView.backgroundColor = nil
        
        // Configure the drag gesture recognizer.
        self.dragGestureRecognizer.delegate = self
        self.dragGestureRecognizer.addTarget(self, action: #selector(updateContentSizeWithRecognizer(_:)))
        
        // Configure the container view.
        self.isOpaque = true
        self.clipsToBounds = false
        self.backgroundColor = nil
        self.translatesAutoresizingMaskIntoConstraints = false
        
        self.addGestureRecognizer(self.dragGestureRecognizer)
        
        self.addLayoutGuide(self.topLayoutGuide)
        self.addLayoutGuide(self.bottomLayoutGuide)
        self.addLayoutGuide(self.intrinsicLayoutGuide)
        
        self.addSubview(self.presentingView)
        self.addConstraints(
            [
                self.presentingView.topAnchor.constraint(equalTo: self.topAnchor),
                self.presentingView.leftAnchor.constraint(equalTo: self.leftAnchor),
                self.presentingView.rightAnchor.constraint(equalTo: self.rightAnchor),
                self.presentingView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
                
                self.topLayoutGuide.topAnchor.constraint(equalTo: self.topAnchor),
                self.topLayoutGuide.leftAnchor.constraint(equalTo: self.leftAnchor),
                
                self.bottomLayoutGuide.leftAnchor.constraint(equalTo: self.leftAnchor),
                
                self.intrinsicLayoutGuide.topAnchor.constraint(equalTo: self.topAnchor),
                self.intrinsicLayoutGuide.leftAnchor.constraint(equalTo: self.leftAnchor),
                
                self.intrinsicLayoutConstraint
            ]
        )
        
        // The bottom layout constraint is not required, because when the content view or header view
        // specifies the size, the alls view will be over out of the container view boundary.
        let bottomLayoutConstraint = self.bottomLayoutGuide.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        bottomLayoutConstraint.priority = .defaultLow - 1
        self.addConstraint(bottomLayoutConstraint)
        
        let weakLayoutConstraints = [
            self.topLayoutGuide.widthAnchor.constraint(equalToConstant: 0),
            self.topLayoutGuide.heightAnchor.constraint(equalToConstant: 0),
            self.bottomLayoutGuide.widthAnchor.constraint(equalToConstant: 0),
            self.bottomLayoutGuide.heightAnchor.constraint(equalToConstant: 0),
            self.intrinsicLayoutGuide.widthAnchor.constraint(equalToConstant: 0)
        ]
        
        // This is an optional constraint to eliminate the warning.
        weakLayoutConstraints.forEach {
            $0.priority = .init(1)
            self.addConstraint($0)
        }
        
        // If there is level 3 or above, the default level 2 is displayed.
        var mheight = orderedLevels.first ?? 0
        if orderedLevels.count > 2 {
            mheight = orderedLevels[1]
        }
        
        // Setup default displayed height.
        self.updateContentSize(mheight)
        
        // Reset origin position.
        self.dragContentOffset.y = mheight
        self.dragContentTranslation.y = mheight
    }
    
    deinit {
        
        // Remove observer when view controller is set.
        self.viewController?.removeObserver(self, forKeyPath: "view")
        self.viewController = nil
        
        // Clear view to prevent additional observer from causing crash.
        self.updateSubview(forHeaderView: nil)
        self.updateSubview(forContentView: nil)
        self.updateSubview(forFooterView: nil)
    }
    
    
    @available(*, unavailable, message: "An embeddable object must be provided, Please initialize using init(embed:).")
    override public init(frame: CGRect) {
        fatalError("An embeddable object must be provided, Please initialize using init(embed:).")
    }
    
    @available(*, unavailable, message: "An embeddable object must be provided, Please initialize using init(embed:).")
    required public init?(coder aDecoder: NSCoder) {
        fatalError("An embeddable object must be provided, Please initialize using init(embed:).")
    }

    
    fileprivate var visibility: CGFloat = 1
    fileprivate var isLockedOffsetChanges: Bool = false
    fileprivate var hasViewController: Bool = false
    
    fileprivate var orderedLevels: Array<CGFloat> = []

    fileprivate var dragContentOffset: CGPoint = .zero
    fileprivate var dragContentTranslation: CGPoint = .zero
    
    fileprivate var dragGestureRecognizer: UIPanGestureRecognizer = .init()
    
    fileprivate let topLayoutGuide: UILayoutGuide = .init()
    fileprivate let bottomLayoutGuide: UILayoutGuide = .init()
    fileprivate let intrinsicLayoutGuide: UILayoutGuide = .init()

    fileprivate let intrinsicLayoutConstraint: NSLayoutConstraint
    
    /// The current effect view.
    fileprivate let presentingView: UIVisualEffectView = .init()

    /// The current tacking view.
    fileprivate weak var trackingView: UIScrollView?

    /// The current associated view controller.
    fileprivate unowned(unsafe) var viewController: UIViewController?
    
    /// Provide a memory address that is available.
    fileprivate static var defaultKey: String = ""
}


/// This copied codes for maintain components independence.
/// The extension `NSObjectProtocol` protocol does not generate category load code.
fileprivate extension NSObjectProtocol {
    
    /// Dynamic inheritance.
    @discardableResult
    @inline(__always) func inheritClass(_ name: String, methods: ((AnyClass) -> ())? = nil) -> Self {
        
        // If the class have created, use it.
        if let clazz = NSClassFromString(name) {
            // If you have inherited it, ignore it.
            if !isKind(of: clazz) {
                object_setClass(self, clazz)
            }
            return self
        }
        
        // Creating a dynamic class.
        if let clazz = objc_allocateClassPair(type(of: self), name, 0)  {
            // Reigster and add methods in dymamic class.
            objc_registerClassPair(clazz)
            methods?(clazz)
            object_setClass(self, clazz)
        }
        
        return self
    }
    
    /// Add a destruct observer.
    @inline(__always) func addDestructObserver(_ callback: @escaping () -> ()) {
        objc_sync_enter(self)
        autoreleasepool {
            let key = UnsafeRawPointer(bitPattern: 0x69236523)!
            if let trigger = objc_getAssociatedObject(self, key) as? NSMutableArray {
                trigger.add(callback)
                return
            }
            // Dynamically inherit a class.
            let trigger = NSMutableArray(object: callback).inheritClass("XCDestructTrigger") {

                // Must using unmanaged object, because object is deallocing can't retain.
                let dealloc: @convention(block) (Unmanaged<NSMutableArray>) -> () = {
                    // Call each registered callback.
                    $0.takeUnretainedValue().forEach {
                        ($0 as? (() -> ()))?()
                    }
                    
                    // Must call `dealloc` for `superclass`, otherwise will occur memory leaks.
                    let sel = Selector(String("dealloc"))
                    if let imp = class_getMethodImplementation($0.takeUnretainedValue().superclass, sel)  {
                        unsafeBitCast(imp, to: (@convention(c) (Unmanaged<NSMutableArray>, Selector) -> Void).self)($0, sel)
                    }
                }
                
                // Reigster and add methods in dymamic class.
                class_addMethod($0, Selector(String("dealloc")), imp_implementationWithBlock(dealloc), "v@")
            }
            objc_setAssociatedObject(self, key, trigger, .OBJC_ASSOCIATION_RETAIN)
        }
        objc_sync_exit(self)
    }
    
    /// Remove all destruct observers.
    @inline(__always) func removeDestructObservers() {
        objc_sync_enter(self)
        autoreleasepool {
            let key = UnsafeRawPointer(bitPattern: 0x69236523)!
            let trigger = objc_getAssociatedObject(self, key) as? NSMutableArray
            trigger?.removeAllObjects()
        }
        objc_sync_exit(self)
    }
}
