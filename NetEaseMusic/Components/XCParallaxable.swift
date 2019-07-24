//
//  XCParallaxable.swift
//  XCParallaxable
//
//  Created by SAGESSE on 2019/6/11.
//  Copyright © 2019 SAGESSE. All rights reserved.
//

import UIKit


public protocol XCParallaxable: class {
    
    /// Configure the vertical parallax animation managing view.
    var parallaxing: XCParallaxingView { get }

}

public extension XCParallaxable where Self: UIView {
    
    /// Configure the vertical parallax animation managing view.
    var parallaxing: XCParallaxingView {
        // If already created, reuse it.
        if let fsObject = objc_getAssociatedObject(self, &XCParallaxingView.defaultKey) as? XCParallaxingView {
            return fsObject
        }
        
        // Create a new implementation object.
        let fsObject = XCParallaxingView(embed: self)
        objc_setAssociatedObject(self, &XCParallaxingView.defaultKey, fsObject, .OBJC_ASSOCIATION_RETAIN)
        return fsObject
    }
    
}
public extension XCParallaxable where Self: UIViewController {
    
    /// Configure the vertical parallax animation managing view.
    var parallaxing: XCParallaxingView {
        // If already created, reuse it.
        if let fsObject = objc_getAssociatedObject(self, &XCParallaxingView.defaultKey) as? XCParallaxingView {
            return fsObject
        }
        
        // Create a new implementation object.
        let fsObject = XCParallaxingView(embed: self)
        objc_setAssociatedObject(self, &XCParallaxingView.defaultKey, fsObject, .OBJC_ASSOCIATION_RETAIN)
        return fsObject
    }

}


@objc
public protocol XCParallaxingViewDelegate: class {
    
    @objc optional func parallaxingView(_ parallaxingView: XCParallaxingView, didChangeOffset offset: CGPoint)
    @objc optional func parallaxingView(_ parallaxingView: XCParallaxingView, didChangeSize size: CGSize)

    @objc optional func parallaxingView(_ parallaxingView: XCParallaxingView, WillChangeOffset offset: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>)

}


@objc
open class XCParallaxingView: UIView {

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

    
    /// A Boolean value that controls whether the scroll view bounces past the edge of content and back again.
    open var isBounces: Bool = true
    
    /// A Boolean value that determines whether scrolling is enabled.
    open var isScrollEnabled: Bool = true

    
    /// Returns the content offset in content view.
    open var contentOffset: CGPoint {
        return cachedContentOffset
    }
    
    /// Returns the content size of content view.
    open var contentSize: CGSize {
        return cachedContentSize
    }

    /// Configure the presented view.
    open var presentedView: UIView {
        return presentingView
    }

    /// Configure the events delegete.
    open weak var delegate: XCParallaxingViewDelegate?
        

    /// Embed a scroll view into parallaxa view.
    open func embed(_ scrollView: UIScrollView) {

        // If the scroll view is already attached, can't be added again.
        guard !scrollViews.contains(scrollView) else {
            return
        }

        scrollViews.add(scrollView)
        scrollView.addObserver(self, forKeyPath: "contentOffset", options: .new, context: .init(mutating: sel_getName(#selector(updateContentOffsetWithObserver(_:)))))
        scrollView.addDestructObserver { [unowned(unsafe) scrollView, weak self] in
            self.map {
                // If the scroll view is destroyed, must to be automatically unembedded.
                scrollView.removeObserver($0, forKeyPath: "contentOffset")
                $0.scrollViews.remove(scrollView)
            }
        }
        
        // Must update content insets when size is set.
        guard cachedContentSize.width != 0 else {
            return
        }

        // Apply changes for prallax view.
        performWithoutContentChanges {
            let oldContentOffset = scrollView.contentOffset
            scrollView.contentInset.top += cachedContentSize.width
            scrollView.scrollIndicatorInsets.top += cachedContentSize.width - cachedContentOffset.y
            scrollView.contentOffset.y = oldContentOffset.y - cachedContentSize.width + cachedContentOffset.y
            scrollView.__parallaxing_contentInsetIncludingDecorationsExtra.top = min(-cachedContentOffset.y, 0)
        }
    }
    
    /// Unembed a scroll view from parallaxa view.
    open func unembed(_ scrollView: UIScrollView) {

        // If the scroll view is not attached, no need to remove.
        guard scrollViews.contains(scrollView) else {
            return
        }

        scrollViews.remove(scrollView)
        scrollView.removeDestructObservers()
        scrollView.removeObserver(self, forKeyPath: "contentOffset")
        
        // Restore changes for parallax view.
        performWithoutContentChanges {
            // Must restore content inset when size is set.
            guard cachedContentSize.width != 0 else {
                return
            }
            scrollView.contentInset.top -= cachedContentSize.width
            scrollView.scrollIndicatorInsets.top -= cachedContentSize.width - cachedContentOffset.y
            scrollView.__parallaxing_contentInsetIncludingDecorationsExtra.top = 0
        }
    }
    
    /// Disables all content offset observer.
    open func performWithoutContentChanges(_ actionsWithoutContentChanges: () -> ()) {
        // Because this method is only executed on the main thread, there is no need to lock it.
        let oldValue = isLockedOffsetChanges
        isLockedOffsetChanges = true
        actionsWithoutContentChanges()
        isLockedOffsetChanges = oldValue
    }
    

    /// Keep the view origin for superview.
    open override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        // Ignore for superview is not change.
        guard superview !== newSuperview else {
            return
        }
        
        // In iOS 11, the `topLayoutGuide` display error of `UITableViewConroller` has been solved.
        if self.hasViewController {
            if #available(iOS 11.0, *) {
                return
            }
        }
        
        // Keep the superview observer status.
        (superview as? UIScrollView).map {
            $0.removeObserver(self, forKeyPath: "contentOffset")
        }
        (newSuperview as? UIScrollView).map {
            $0.addObserver(self, forKeyPath: "contentOffset", options: [.initial, .new], context: .init(mutating: sel_getName(#selector(updateSuperviewOffsetWithObserver(_:)))))
        }
    }
    
    /// Forward all touch events in this view.
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {

        // Compute the current hit-tested first responder.
        guard let firstResponder = super.hitTest(point, with: event) else {
            return nil
        }
        
        // If the superview has multiple subviews, try forwarding to the previous first responder.
        guard let subviews = superview?.subviews, let index = subviews.firstIndex(of: self), index != 0 else {
            return firstResponder
        }

        // Compute the candidate hit-tested first responder.
        guard let secondResponder = forwardingHitTest(point, with: event, in: .init(subviews[..<index])) else {
            return firstResponder
        }

        // forwarding all touch event to gate view.
        return XCParallaxingGateView(firstResponder, secondResponder: secondResponder, in: superview)
    }
    
    /// Automatically perform to the specified method for context.
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        context.map {
            _ = perform(sel_registerName($0.assumingMemoryBound(to: Int8.self)), with: object, with: change)
        }
    }
    
    /// The content size needs to be updated when the size of the subview changes.
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update content size when size is change.
        updateContentSizeIfNeeded()
        
        // FIXME: When the screen is rotated, the content inset is out of sync.
    }

    
    fileprivate func updateContentSize(_ offset: CGSize) {
        
        // Calculate the vaild content offset.
        let oldContentOffset = cachedContentOffset.y
        cachedContentOffset.y = align(cachedContentOffsetWithRaw.y)
        
        // Apply content offset when height is change.
        let availableContentOffset = offset.height - (cachedContentOffset.y - oldContentOffset)
        if availableContentOffset != 0 {
            updateContentOffset(.init(dx: 0, dy: availableContentOffset))
        }

        // Apply the size changes to all embbed scrollViews.
        // modify `contentInsetIncludingDecorations` won't update any UI,
        // so must be set before the update `contentinset`.
        updateContentInsetIncludingDecorationsIfNeeded()
        updateContentInsets(.init(dx: 0, dy: offset.width))
        updateContentIndicatorInsets(.init(dx: 0, dy: offset.width - offset.height + availableContentOffset))
    }
    fileprivate func updateContentSizeIfNeeded() {
        
        // Calculate the current real height.
        let height = intrinsicLayoutGuide.frame.height
        var width = height + bottomLayoutGuide.layoutFrame.height
        
        // In iOS 10, when there no navigation controller, the `contentInsets` of `scrollView` is zero,
        // But the `contentInsets` of `scrollView` is normal when has navigation controller.
        if let viewController = viewController, viewController.navigationController == nil {
            if #available(iOS 11, *) {
                // In iOS 11+, the bug is fixed.
            } else {
                // In iOS 10, add `contentInsets` differences to the `contentSize`.
                width += topLayoutGuide.layoutFrame.height
            }
        }
        
        // Ignore it when the size doesn't change.
        guard width != cachedContentSize.width else {
            return
        }
        let oldValue = cachedContentSize
        
        // Update & cache content size.
        cachedContentSize = .init(width: width, height: height)
        updateContentSize(.init(width: width - oldValue.width,
                                height: height - oldValue.height))
        
        delegate?.parallaxingView?(self, didChangeSize: cachedContentSize)
    }
    
    fileprivate func updateContentOffset(_ offset: CGVector) {
        // Only update when the offset is changed.
        guard offset != .zero else {
            return
        }
        // Synchronize content offset changed results to User Interface.
        presentingLayoutConstraint.constant -= offset.dy

        // If the content is zero, the calculation does not make sense.
        delegate?.parallaxingView?(self, didChangeOffset: cachedContentOffset)

        // Joint change is automatic synchronization when multiple `scrollView` exists.
        guard isAutomaticallyLinking, scrollViews.count > 1 else {
            return
        }

        // Synchronize all offset changes to other scrollViews.
        performWithoutContentChanges {
            scrollViews.allObjects.forEach {
                
                // Get the content offset from scrollView.
                let oldValue = contentOffset($0.contentOffset, from: $0)
                
                // If `contentOffset` does not change, it is ignored.
                guard oldValue.y != cachedContentOffset.y else {
                    return
                }
                
                // Convert to scrollView coordinate after the content offset may be overbound of the content size
                // Must fix it but if fixed content offset is equal to the current content offset, ignore it.
                let newValue = contentOffset(cachedContentOffset, to: $0)
                guard newValue.y != $0.contentOffset.y else {
                    return
                }

                $0.contentOffset = newValue
            }
        }
    }
    fileprivate func updateContentOffsetIfNeeded(_ offset: CGPoint) {
        // A new content offset is generated.
        cachedContentOffsetWithRaw = offset

        // Ignore update events when content offset is no change.
        let dy = align(offset.y) - cachedContentOffset.y
        guard dy != 0 else {
            return
        }

        // Cache content offset to determine whether the next update is valid.
        cachedContentOffset.y += dy

        // The UI is updated only when automatic updates are turned on.
        guard !isLockedOffsetChanges else {
            return
        }

        updateContentOffset(.init(dx: 0, dy: -dy))
        updateContentInsetIncludingDecorationsIfNeeded()
        updateContentIndicatorInsets(.init(dx: 0, dy: -dy))
    }
    
    @objc fileprivate func updateContentOffsetWithObserver(_ scrollView: UIScrollView) {
        // Checks whether the current state allows for scroll events to be update.
        guard !isLockedOffsetChanges, isScrollEnabled else {
            return
        }
        
        // Start linkage all emabed scrollViews.
        isAutomaticallyLinking = true
        
        // Automatic update content offset.
        updateContentOffsetIfNeeded(contentOffset(scrollView.contentOffset, from: scrollView))
        
        // When the update is finished, it is forbidden.
        isAutomaticallyLinking = false
    }

    fileprivate func updateContentInsets(_ offset: CGVector) {
        // Only update when the offset is changed.
        guard offset != .zero else {
            return
        }
        // Synchronize all changes to all embed scrollViews.
        performWithoutContentChanges {
            scrollViews.allObjects.forEach {
                updateContentInsets(offset, for: $0)
            }
        }
    }
    fileprivate func updateContentInsets(_ offset: CGVector, for scrollView: UIScrollView) {
        // When setting up `contentInset`, need to readjust the `contentOffset`.
        let minHeight = topLayoutGuide.layoutFrame.height
        let contentOffset = scrollView.contentOffset
        
        // The `XCParallaxingView` only needs handle the `top` of the `contentInset` for scrollView..
        scrollView.contentInset.top += offset.dy

        // If the new contentOffset is not any change, don’t restore contentOffset.
        // example:
        //   -388 - 40 = -428 O/O/A
        //   -388 + 40 = -348 O/O/D
        //   -132 - 40 = -172 O/O/A
        //   -132 + 40 = -92  X/X/D
        //   -92  - 40 = -132 X/X/A
        //   -88  - 40 = -128 X/X/A
        //   -112 - 40 = -152 O/X/A
        //   -152 + 40 = -112 X/O/D
        guard contentOffset.y < -minHeight || contentOffset.y - offset.dy < -minHeight else {
            return
        }

        // Sometimes contentOffset added too many offset, so it needs to be limit.
        scrollView.contentOffset.y = min(contentOffset.y - offset.dy, -minHeight)
    }
    
    fileprivate func updateContentIndicatorInsets(_ offset: CGVector) {
        // Only update when the offset is changed.
        guard offset != .zero else {
            return
        }
        // Synchronize all changes to all embed scrollViews.
        performWithoutContentChanges {
            scrollViews.allObjects.forEach {
                updateContentIndicatorInsets(offset, for: $0)
            }
        }
    }
    fileprivate func updateContentIndicatorInsets(_ offset: CGVector, for scrollView: UIScrollView) {
        // The indicator must to follow a content offset to move.
        scrollView.scrollIndicatorInsets.top += offset.dy
    }

    fileprivate func updateContentInsetIncludingDecorationsIfNeeded() {
        // Fix pinned view origin error issue.
        performWithoutContentChanges {
            scrollViews.allObjects.forEach {
                $0.__parallaxing_contentInsetIncludingDecorationsExtra.top = min(-cachedContentOffset.y, 0)
            }
        }
    }

    fileprivate func updateSubview(forHeaderView newValue: UIView?) {
        // If the new value not any changes, ignore it.
        guard newValue?.superview !== self else {
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
        newValue.setContentHuggingPriority(.required - 200, for: .vertical)
        newValue.setContentCompressionResistancePriority(.required - 200, for: .vertical)

        // Add the view to the container view.
        insertSubview(newValue, aboveSubview: intrinsicLayoutGuide)
        
        // Restore header view constraints.
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
        guard newValue?.superview !== presentingView else {
            return
        }

        // First remove the view to clear the constraint.
        contentView?.removeFromSuperview()
        
        // Second check the header view needs to be re-added.
        guard let newValue = newValue else {
            return
        }
        
        // Configure the header view.
        newValue.translatesAutoresizingMaskIntoConstraints = false
        newValue.setContentHuggingPriority(.required - 200, for: .vertical)
        newValue.setContentCompressionResistancePriority(.required - 200, for: .vertical)

        // Add the view to the container view.
        presentingView.addSubview(newValue)
        
        // Restore content view constraints.
        NSLayoutConstraint.activate(
            [
                newValue.leftAnchor.constraint(equalTo: presentingView.leftAnchor),
                newValue.rightAnchor.constraint(equalTo: presentingView.rightAnchor),
                newValue.bottomAnchor.constraint(equalTo: presentingView.bottomAnchor),
                newValue.heightAnchor.constraint(equalTo: intrinsicLayoutGuide.heightAnchor)
            ]
        )
    }
    fileprivate func updateSubview(forFooterView newValue: UIView?) {
        // If the new value not any changes, ignore it.
        guard newValue?.superview !== self else {
            return
        }
        
        // First remove the view to clear the constraint.
        footerView?.removeFromSuperview()
        
        // Second check the header view needs to be re-added.
        guard let newValue = newValue else {
            return
        }
        
        // Configure the header view.
        newValue.translatesAutoresizingMaskIntoConstraints = false
        newValue.setContentHuggingPriority(.required - 200, for: .vertical)
        newValue.setContentCompressionResistancePriority(.required - 200, for: .vertical)

        // Add the view to the container view.
        insertSubview(newValue, aboveSubview: intrinsicLayoutGuide)

        // Restore footer view constraints.
        NSLayoutConstraint.activate(
            [
                newValue.topAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor),
                newValue.leftAnchor.constraint(equalTo: presentingView.leftAnchor),
                newValue.rightAnchor.constraint(equalTo: presentingView.rightAnchor),
                newValue.heightAnchor.constraint(equalTo: bottomLayoutGuide.heightAnchor)
            ]
        )
    }

    fileprivate func updateSuperview(_ superview: UIView?) {
        
        // If the superview is changes, reattach it.
        guard superview !== self.superview else {
            return
        }
        
        // First remove container view from view controller, so that the constraint is automatically remove.
        removeFromSuperview()
        
        // If superview is nil, it is only remove without adding.
        guard let superview = superview else {
            return
        }
        
        // And then add the container view to view controller.
        superview.addSubview(self)

        // If the superview is a scrollview, can't use rightAnchor.
        let offsetLayoutConstraint = topAnchor.constraint(equalTo: superview.topAnchor)

        // Finally restore the view controller constraints.
        NSLayoutConstraint.activate(
            [
                offsetLayoutConstraint,
                leftAnchor.constraint(equalTo: superview.leftAnchor),
                widthAnchor.constraint(equalTo: superview.widthAnchor),
            ]
        )
        
        // Save the dynamic offset layout constraint.
        self.offsetLayoutConstraint = offsetLayoutConstraint

        // Trying to restore subview.
        headerView.map { updateSubview(forHeaderView: $0) }
        contentView.map { updateSubview(forContentView: $0) }
        footerView.map { updateSubview(forFooterView: $0) }
    }
    
    @objc fileprivate func updateSuperviewWithObserver(_ viewController: UIViewController) {
        
        // Apply superview for view controller.
        updateSuperview(viewController.view)
        
        // Apply top layout guide for view controller.
        NSLayoutConstraint.activate([viewController.topLayoutGuide.heightAnchor.constraint(equalTo: self.topLayoutGuide.heightAnchor)])
        
        if viewController is UITableViewController {
            // In iOS 11, the `topLayoutGuide` display error of UITableViewConroller has been solved.
            guard #available(iOS 11, *) else {
                return
            }
        }
        
        // In view controller don't use the top layout constraint.
        offsetLayoutConstraint?.isActive = false
        
        // Activate the top layout guide for view controller.
        NSLayoutConstraint.activate([viewController.topLayoutGuide.topAnchor.constraint(equalTo: self.topLayoutGuide.topAnchor)])
    }
    @objc fileprivate func updateSuperviewOffsetWithObserver(_ scrollView: UIScrollView) {
        
        // Update top constraint for content offset y is changed.
        if scrollView.contentOffset.y != offsetLayoutConstraint?.constant {
            offsetLayoutConstraint?.constant = scrollView.contentOffset.y
        }
    }
    
    
    @inline(__always) fileprivate func forwardingHitTest(_ point: CGPoint, with event: UIEvent?, in subviews: [UIView]) -> UIView? {
        for view in subviews.reversed() {
            // If multiple subviews exist, look back and forward.
            if let hited = view.hitTest(convert(point, to: view), with: event) {
                return hited
            }
        }
        return nil
    }
    
    @inline(__always) fileprivate func contentOffset(_ offset: CGPoint, from scrollView: UIScrollView) -> CGPoint {
        let edg: UIEdgeInsets
        
        // In iOS11, must use `adjustedContentInset`
        if #available(iOS 11.0, *) {
            edg = scrollView.adjustedContentInset
        } else {
            edg = scrollView.contentInset
        }
        
        return .init(x: offset.x + edg.left, y: offset.y + edg.top)
    }
    @inline(__always) fileprivate func contentOffset(_ offset: CGPoint, to scrollView: UIScrollView) -> CGPoint {
        let edg: UIEdgeInsets
        
        // In iOS11, must use `adjustedContentInset`
        if #available(iOS 11.0, *) {
            edg = scrollView.adjustedContentInset
        } else {
            edg = scrollView.contentInset
        }
        
        return .init(x: max(-edg.left + offset.x, -edg.left), y: max(-edg.top + offset.y, -edg.top))
    }
    
    @inline(__always) fileprivate func align(_ offset: CGFloat) -> CGFloat {
        
        // Hovering over the top.
        var newValue = CGPoint(x: 0, y: min(offset, intrinsicLayoutGuide.frame.height))
        
        // If a bounce is prohibited, limit the maximum.
        if !isBounces {
            newValue.y = max(newValue.y, 0)
        }
        
        // Apply for delegate.
        delegate?.parallaxingView?(self, WillChangeOffset: .init(x: 0, y: offset), targetContentOffset: &newValue)
        return newValue.y
    }
    

    /// Common init.
    fileprivate init() {
        
        // Resolved components API dependencies.
        _ = XCParallaxingView.resolvedDependencies

        // Create a intrinsic layout constraint.
        self.presentingLayoutConstraint = self.topLayoutGuide.bottomAnchor.constraint(equalTo: self.bottomLayoutGuide.topAnchor)

        // Build base view.
        super.init(frame: CGRect(x: 0, y: 0, width: 375, height: 240))

        // Configure the presenting view.
        self.presentingView.bounds = self.bounds
        self.presentingView.isOpaque = true
        self.presentingView.clipsToBounds = true
        self.presentingView.backgroundColor = nil
        self.presentingView.translatesAutoresizingMaskIntoConstraints = false

        self.intrinsicLayoutGuide.isHidden = true
        self.intrinsicLayoutGuide.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure the container view.
        self.isOpaque = true
        self.clipsToBounds = false
        self.backgroundColor = nil
        self.translatesAutoresizingMaskIntoConstraints = false

        self.addLayoutGuide(self.topLayoutGuide)
        self.addLayoutGuide(self.bottomLayoutGuide)

        self.addSubview(self.presentingView)
        self.addSubview(self.intrinsicLayoutGuide)

        self.addConstraints(
            [
                self.presentingView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor),
                self.presentingView.leftAnchor.constraint(equalTo: self.leftAnchor),
                self.presentingView.rightAnchor.constraint(equalTo: self.rightAnchor),
                self.presentingView.bottomAnchor.constraint(equalTo: self.bottomLayoutGuide.topAnchor).priority(.required - 201),

                self.topLayoutGuide.topAnchor.constraint(equalTo: self.topAnchor),
                self.topLayoutGuide.leftAnchor.constraint(equalTo: self.leftAnchor),
                self.topLayoutGuide.widthAnchor.constraint(equalToConstant: 0),
                self.topLayoutGuide.heightAnchor.constraint(equalToConstant: 0).priority(.required - 201),

                self.intrinsicLayoutGuide.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor),
                self.intrinsicLayoutGuide.leftAnchor.constraint(equalTo: self.leftAnchor),
                self.intrinsicLayoutGuide.widthAnchor.constraint(equalToConstant: 0),
                
                self.bottomLayoutGuide.leftAnchor.constraint(equalTo: self.leftAnchor),
                self.bottomLayoutGuide.bottomAnchor.constraint(equalTo: self.bottomAnchor),
                self.bottomLayoutGuide.widthAnchor.constraint(equalToConstant: 0),
                self.bottomLayoutGuide.heightAnchor.constraint(equalToConstant: 0).priority(.required - 201),

                self.presentingLayoutConstraint
            ]
        )
    }
    

    deinit {
        
        // Remove observer when view controller is set.
        self.viewController?.removeObserver(self, forKeyPath: "view")
        self.viewController = nil

        // Clean attached scroll view.
        self.scrollViews.allObjects.forEach {
            self.unembed($0)
        }
        
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

    
    fileprivate var hasViewController: Bool = false

    fileprivate var isLockedOffsetChanges: Bool = false
    fileprivate var isAutomaticallyLinking: Bool = false
    
    // If the cached content property has any changes, will trigger the update again.
    fileprivate var cachedContentSize: CGSize = .zero
    fileprivate var cachedContentOffset: CGPoint = .zero
    fileprivate var cachedContentOffsetWithRaw: CGPoint = .zero

    fileprivate let topLayoutGuide: UILayoutGuide = .init()
    fileprivate let bottomLayoutGuide: UILayoutGuide = .init()
    fileprivate let intrinsicLayoutGuide: UIView = .init()

    fileprivate var offsetLayoutConstraint: NSLayoutConstraint?
    fileprivate var presentingLayoutConstraint: NSLayoutConstraint
    
    fileprivate var scrollViews: NSHashTable<UIScrollView> = .init(options: .opaqueMemory)
    fileprivate let presentingView: UIView = .init()

    // The current associated view controller.
    fileprivate unowned(unsafe) var viewController: UIViewController?

    // Provide a memory address that is available.
    fileprivate static var defaultKey: String = ""
    fileprivate static var extraKey: String = ""
    
    // Load all resolved dependencies.
    fileprivate static var resolvedDependencies: Void = {
        
        let m1 = class_getInstanceMethod(UIScrollView.self, NSSelectorFromString("_contentInsetIncludingDecorations"))
        let m2 = class_getInstanceMethod(UIScrollView.self, NSSelectorFromString("__parallaxing_contentInsetIncludingDecorations"))
        if let org = m1, let new = m2 {
            method_exchangeImplementations(org, new)
        }
        
        let m3 = class_getInstanceMethod(NSClassFromString("UITouchesEvent"), NSSelectorFromString("touchesForView:"))
        let m4 = class_getInstanceMethod(NSClassFromString("UITouchesEvent"), NSSelectorFromString("__parallaxing_touchesForView:"))
        if let org = m3, let new = m4 {
            method_exchangeImplementations(org, new)
        }

    }()
}


// The event gateway.
fileprivate class XCParallaxingGateView: UIView {
    
    convenience init(_ firstResponder: UIView?, secondResponder: UIView?, in superview: UIView?) {
        self.init()
        self.hitedSuperview = superview
        self.hitedFirstResponder = firstResponder
        self.hitedSecondResponder = secondResponder
    }
    
    deinit {
        // Force the cancellation of all possible pan gesture recognizers.
        for otherGestureRecognizer in firstGestureRecognizers {
            if otherGestureRecognizer.state == .possible && otherGestureRecognizer.isKind(of: XCParallaxingGateView.scrollViewPanGestureRecognizer) {
                otherGestureRecognizer.state = .cancelled
            }
        }
    }
    
    // The super.touchesXXX will query responder chain.
    override var next: UIResponder? {
        return hitedFirstResponder
    }
    
    // The super.touchesXXX will query the hierarchy window.
    override var window: UIWindow? {
        return hitedSuperview?.window
    }
    
    // The gesture recognizers system will query the hierarchy.
    override var superview: UIView? {
        return hitedFirstResponder
    }
    
    // The gesture recognizers system will query the gesture recognizers for each view.
    override var gestureRecognizers: [UIGestureRecognizer]? {
        set {}
        get {
            // Check the first respodner view hierarchy.
            var firstHierarchyView = hitedFirstResponder
            while firstHierarchyView != nil, firstHierarchyView != hitedSuperview {
                
                // Merge gestures recognizers, noting that they must be added forward.
                firstHierarchyView?.gestureRecognizers.map {
                    firstGestureRecognizers.append(contentsOf: $0)
                }
                
                // Get next hierarchy view.
                firstHierarchyView = firstHierarchyView?.superview
            }
            
            // Check the second respodner view hierarchy.
            var secondHierarchyView = hitedSecondResponder
            while secondHierarchyView != nil, secondHierarchyView != hitedSuperview {

                // Merge gestures recognizers, noting that they must be added forward.
                secondHierarchyView?.gestureRecognizers.map {
                    secondGestureRecognizers.append(contentsOf: $0)
                }

                // Get next hierarchy view.
                secondHierarchyView = secondHierarchyView?.superview
            }
            
            return firstGestureRecognizers + secondGestureRecognizers
        }
    }
    
    // The gesture recognizers system will view type.
    override func isKind(of aClass: AnyClass) -> Bool {
        // Because if the first responser view is button, system has special processing.
        if let firstResponder = hitedFirstResponder {
            return firstResponder.isKind(of: aClass)
        }
        return super.isKind(of: aClass)
    }
    
    // Always return true, because only events in this view hierarchy are added.
    override func isDescendant(of view: UIView) -> Bool {
        return true
    }
    
    // Forwarding all unknow message to first responder view.
    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return hitedFirstResponder
    }

    // Cancel other pan gestures when the pan gesture is activated.
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {

        // Only process the scroll view pan gesture recognizer.
        let result = super.gestureRecognizerShouldBegin(gestureRecognizer)
        guard result && gestureRecognizer.isKind(of: XCParallaxingGateView.scrollViewPanGestureRecognizer) else {
            return result
        }
        
        // Check which view hierarchy the responses are in.
        guard firstGestureRecognizers.contains(gestureRecognizer) else {
            // If the first responder view already respond, the second responder view can't respond.
            for otherGestureRecognizer in firstGestureRecognizers {
                if otherGestureRecognizer.state != .possible && otherGestureRecognizer.isKind(of: XCParallaxingGateView.scrollViewPanGestureRecognizer) {
                    return false
                }
            }
            return true
        }

        // Cancel all scroll view pan gesture recognizers except self.
        for otherGestureRecognizer in firstGestureRecognizers + secondGestureRecognizers {
            if otherGestureRecognizer !== gestureRecognizer && otherGestureRecognizer.isKind(of: XCParallaxingGateView.scrollViewPanGestureRecognizer) {
                if otherGestureRecognizer.state != .ended && otherGestureRecognizer.state != .cancelled {
                    otherGestureRecognizer.state = .cancelled
                }
            }
        }

        return true
    }

    fileprivate weak var hitedSuperview: UIView?
    fileprivate weak var hitedFirstResponder: UIView?
    fileprivate weak var hitedSecondResponder: UIView?
    
    fileprivate lazy var firstGestureRecognizers: [UIGestureRecognizer] = []
    fileprivate lazy var secondGestureRecognizers: [UIGestureRecognizer] = []
    
    // Get the `panGestureRecognizer` runtime type of `UIScrollView` instance.
    fileprivate static let scrollViewPanGestureRecognizer = type(of: UIScrollView().panGestureRecognizer)
}

// Fix the `UIControl` does not respond to the issue.
fileprivate extension UIEvent {
    
    // Because we forwarding the touches event to gateView,
    // so UIButton can't using "touchesForView:" to query the touch.
    @objc dynamic func __parallaxing_touchesForView(_ view: UIView) -> Set<UITouch>? {
  
        // Because only `UIControl` has a issue, only need to process with it.
        let touches = __parallaxing_touchesForView(view)
        guard touches == nil, view is UIControl else {
            return touches
        }

        // Additional find in gateway view.
        for touch in allTouches ?? [] {
            if view === (touch.view as? XCParallaxingGateView)?.hitedFirstResponder {
                return [touch]
            }
        }
        return nil
    }

}

// Fix `UITableView` panned view origin error issue.
fileprivate extension UIScrollView {
    
    // Record the extra adding `contentInset`.
    @inline(__always) var __parallaxing_contentInsetIncludingDecorationsExtra: UIEdgeInsets {
        set { return objc_setAssociatedObject(self, &XCParallaxingView.extraKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get { return objc_getAssociatedObject(self, &XCParallaxingView.extraKey) as? UIEdgeInsets ?? .zero }
    }
    
    // In `UIScrollView` the `contentInset` modification, will leads to `UITableView` the pinned view origin error.
    // This issue resolved by adding `includingDecorations`, But this is a undocumented API, it work in iOS 9 - iOS 13(or more).
    @objc dynamic func __parallaxing_contentInsetIncludingDecorations() -> UIEdgeInsets {
        var newContentInsets = __parallaxing_contentInsetIncludingDecorations()
        newContentInsets.top += __parallaxing_contentInsetIncludingDecorationsExtra.top
        return newContentInsets
    }
    
}

/// Quickly set up.
fileprivate extension NSLayoutConstraint {
    @inline(__always) func priority(_ priority: UILayoutPriority) -> NSLayoutConstraint {
        self.priority = priority
        return self
    }
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
                    let sel = NSSelectorFromString("dealloc")
                    if let imp = class_getMethodImplementation($0.takeUnretainedValue().superclass, sel)  {
                        unsafeBitCast(imp, to: (@convention(c) (Unmanaged<NSMutableArray>, Selector) -> Void).self)($0, sel)
                    }
                }
                
                // Reigster and add methods in dymamic class.
                class_addMethod($0, NSSelectorFromString("dealloc"), imp_implementationWithBlock(dealloc), "v@")
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
