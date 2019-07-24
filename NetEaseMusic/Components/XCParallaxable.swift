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
        if let view = objc_getAssociatedObject(self, &XCParallaxingView.defaultKey) as? XCParallaxingView {
            return view
        }
        
        // Create a new implementation object.
        let view = XCParallaxingView(embed: self)
        objc_setAssociatedObject(self, &XCParallaxingView.defaultKey, view, .OBJC_ASSOCIATION_RETAIN)
        return view
    }
    
}
public extension XCParallaxable where Self: UIViewController {
    
    /// Configure the vertical parallax animation managing view.
    var parallaxing: XCParallaxingView {
        // If already created, reuse it.
        if let view = objc_getAssociatedObject(self, &XCParallaxingView.defaultKey) as? XCParallaxingView {
            return view
        }
        
        // Create a new implementation object.
        let view = XCParallaxingView(embed: self)
        objc_setAssociatedObject(self, &XCParallaxingView.defaultKey, view, .OBJC_ASSOCIATION_RETAIN)
        return view
    }
    
}

@objc
public protocol XCParallaxingViewDelegate: class {
    
    @objc optional func parallaxingView(_ parallaxingView: XCParallaxingView, didChangeOffset offset: CGPoint)
    @objc optional func parallaxingView(_ parallaxingView: XCParallaxingView, didChangeSize size: CGSize)
    
    @objc optional func parallaxingView(_ parallaxingView: XCParallaxingView, willChangeOffset offset: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>)
    
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
    
    /// A Boolean value that determines whether scrolling pinned is enabled.
    open var isPinnedEnabled: Bool = false

    /// A Boolean value that indicates whether the view forward all touchs to subview's for same superview.
    open var isForwardTouchEnabled: Bool = true
    
    /// A Boolean value that indicates whether the parallaxing view should automatically adjust its embedded scroll view content insets.
    open var automaticallyAdjustsEmbeddedViewInset: Bool = true
    
    
    /// Returns the content offset in content view.
    open var contentOffset: CGPoint {
        get { return cachedContentOffset }
        set { return setContentOffset(newValue, animated: false) }
    }
    
    /// Returns the content size of content view.
    open var contentSize: CGSize {
        return .init(width: frame.width, height: cachedContentSize.height)
    }
    
    /// Use this property to extend the space between your content and the edges of the content view. The unit of size is points. The default value is UIEdgeInsetsZero.
    open var contentInset: UIEdgeInsets = .zero {
        willSet {
            insetTopLayoutConstraint?.constant = newValue.top
            insetLeftLayoutConstraint?.constant = newValue.left
            insetRightLayoutConstraint?.constant = -newValue.right
            insetBottomLayoutConstraint?.constant = -newValue.bottom
        }
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
        let extra = scrollView.extra
        guard !scrollViews.contains(extra) else {
            return
        }
        
        scrollViews.insert(extra)
        scrollView.addObserver(self, forKeyPath: "contentOffset", options: .new, context: .init(mutating: sel_getName(#selector(updateContentOffsetWithObserver(_:)))))
        scrollView.addObserver(self, forKeyPath: "panGestureRecognizer.state", options: .new, context: .init(mutating: sel_getName(#selector(updateContentOffsetStatusWithObserver(_:)))))
        scrollView.addDestructObserver { [unowned(unsafe) extra, weak self] in
            self.map {
                // If the scroll view is destroyed, must to be automatically unembedded.
                extra.scrollView.removeObserver($0, forKeyPath: "contentOffset")
                extra.scrollView.removeObserver($0, forKeyPath: "panGestureRecognizer.state")
                $0.scrollViews.remove(extra)
            }
        }
        
        // When user disable automatically adjusts options, ignore.
        guard automaticallyAdjustsEmbeddedViewInset, cachedContentSizeWithRaw.height != 0 else {
            return
        }

        // Apply changes for prallax view.
        performWithoutContentChanges {
            var insets = cachedContentSizeWithRaw.height
            
            if adjusted(scrollView) {
                insets = cachedContentSizeWithRaw.width
            }
            
            let oldContentOffset = rebase(scrollView.contentOffset, from: scrollView)
            extra.scrollDecorationsInsets.top = min(-cachedContentOffset.y, 0)
            extra.contentInset.top = insets
            extra.scrollIndicatorInsets.top = max(insets - cachedContentOffset.y, 0)
            extra.contentOffset.y = max(oldContentOffset.y + pinnedContentOffset.y, 0)
            scrollView.contentOffset.y = rebase(oldContentOffset, to: scrollView).y + cachedContentOffset.y
        }
    }
    
    /// Unembed a scroll view from parallaxa view.
    open func unembed(_ scrollView: UIScrollView) {
        // If the scroll view is not attached, no need to remove.
        let extra = scrollView.extra
        guard scrollViews.contains(extra) else {
            return
        }
        
        scrollView.removeObserver(self, forKeyPath: "contentOffset")
        scrollView.removeObserver(self, forKeyPath: "panGestureRecognizer.state")
        scrollView.removeDestructObservers()
        scrollViews.remove(extra)

        // When user disable automatically adjusts options, ignore.
        guard automaticallyAdjustsEmbeddedViewInset, cachedContentSizeWithRaw.height != 0 else {
            return
        }

        // Restore changes for parallax view.
        performWithoutContentChanges {
            extra.scrollDecorationsInsets.top = 0
            extra.contentInset.top = 0
            extra.contentOffset.y = 0
            extra.scrollIndicatorInsets.top = 0
        }
    }
    
    /// animate at constant velocity to new offset
    open func setContentOffset(_ contentOffset: CGPoint, animated: Bool) {
        UIView.animate(withDuration: 0.3) {
            UIView.setAnimationBeginsFromCurrentState(true)
            self.updateContentOffsetIfNeeded(contentOffset)
            self.superview?.layoutIfNeeded()
        }
    }
    
    
    /// Disables all content offset observer.
    open func performWithoutContentChanges(_ actionsWithoutContentChanges: () -> Void) {
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
    
    /// The content size needs to be updated when the size of the subview changes.
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update content size when size is change.
        updateContentSizeIfNeeded()
        
        // FIXME: When the screen is rotated, the content inset is out of sync.
    }
    
    /// Forward all touch events in this view.
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Compute the current hit-tested first responder.
        guard let firstResponder = super.hitTest(point, with: event) else {
            return nil
        }
        
        // If the superview has multiple subviews, try forwarding to the previous first responder.
        guard let subviews = superview?.subviews, let index = subviews.firstIndex(of: self), index != 0, isForwardTouchEnabled else {
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
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        context.map {
            _ = perform(sel_registerName($0.assumingMemoryBound(to: Int8.self)), with: object, with: change)
        }
    }
    
    
    fileprivate func updateContentSize(_ offset: CGVector, insets: (UIScrollView) -> CGSize) {

        // Calculate the vaild content offset.
        let oldContentOffset = cachedContentOffset.y
        cachedContentOffset.y = rebase(cachedContentOffsetWithRaw.y)

        // Apply content offset when height is change.
        let availableContentOffset = (offset.dy) - (cachedContentOffset.y - oldContentOffset)
        if availableContentOffset != 0 {
            updateContentOffset(.init(dx: 0, dy: availableContentOffset))
        }
        
        // When user disable automatically adjusts options, ignore.
        guard automaticallyAdjustsEmbeddedViewInset else {
            return
        }
        
        // Apply the size changes to all embbed scrollViews.
        // modify `contentInsetIncludingDecorations` won't update any UI,
        // so must be set before the update `contentInset`.
        performWithoutContentChanges {
            scrollViews.forEach {
                updateContentDecorationsInsets(.init(x: 0, y: -cachedContentOffset.y), for: $0)
                updateContentInsets(.init(dx: 0, dy: insets($0.scrollView).height), for: $0)
                updateContentIndicatorInsets(.init(dx: 0, dy: insets($0.scrollView).width + availableContentOffset), for: $0)
            }
        }
    }
    fileprivate func updateContentSizeIfNeeded() {
        // Get all height for guides.
        let top = topLayoutGuide.layoutFrame.height
        let bottom = bottomLayoutGuide.layoutFrame.height
        let intrinsic = intrinsicLayoutGuide.frame.size.height
        let navigationBar = viewController?.topLayoutGuide.length ?? 0
        
        // When the height or width not any changes ignore.
        let dh = (top + bottom + intrinsic) - cachedContentSizeWithRaw.height
        let dw = (top + bottom + intrinsic - navigationBar) - cachedContentSizeWithRaw.width
        let dy = (intrinsic - cachedContentSize.height)
        guard dy != 0 || dw != 0 || dh != 0 else {
            return
        }
        
        // Update cache & content size.
        cachedContentSize.height += dy
        cachedContentSizeWithRaw = .init(width: cachedContentSizeWithRaw.width + dw, height: cachedContentSizeWithRaw.height + dh)
        updateContentSize(.init(dx: 0, dy: dy)) {
            if adjusted($0) {
                return .init(width: dw - dy, height: dw)
            }
            return .init(width: dh - dy, height: dh)
        }
        
        // Notify user the content size is change.
        delegate?.parallaxingView?(self, didChangeSize: cachedContentSize)
    }
    
    fileprivate func updateContentOffset(_ offset: CGVector) {
        // Only update when the offset is changed.
        guard offset != .zero else {
            return
        }
        // Synchronize content offset changed results to User Interface.
        presentingLayoutConstraint.constant -= offset.dy
        
        // Ignore all changes when synchronize.
        performWithoutContentChanges {
            // Joint change is automatic synchronization when multiple `scrollView` exists.
            guard scrollViews.count > 1 else {
                return
            }
            
            // Synchronize all offset changes to other scrollViews.
            scrollViews.forEach {
                // Ignore the activing view.
                guard $0.scrollView !== activingView else {
                    return
                }
                
                // Convert to scrollView coordinate after the content offset may be overbound of the content size
                // Must fix it but if fixed content offset is equal to the current content offset, ignore it.
                let newValue = rebase(cachedContentOffset, to: $0.scrollView)
                guard newValue != $0.scrollView.contentOffset else {
                    return
                }
                
                // If want to adjust the offset,  don't need to check whether it is beyond the boundary.
                guard !isPinnedEnabled || newValue.y - $0.scrollView.contentOffset.y >= -offset.dy else {
                    return
                }
                
                $0.scrollView.contentOffset = newValue
            }
        }
        
        // If the content is zero, the calculation does not make sense.
        delegate?.parallaxingView?(self, didChangeOffset: cachedContentOffset)
    }
    fileprivate func updateContentOffsetIfNeeded(_ offset: CGPoint) {
        // A new content offset is generated.
        cachedContentOffsetWithRaw = offset
        
        // Ignore update events when content offset is no change.
        let dy = rebase(offset.y) - cachedContentOffset.y
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
        updateContentDecorationsInsetsIfNeeded()
        updateContentIndicatorInsets(.init(dx: 0, dy: -dy))
    }

    @objc
    fileprivate func updateContentOffsetWithObserver(_ scrollView: UIScrollView) {
        // Checks whether the current state allows for scroll events to be update.
        guard !isLockedOffsetChanges, isScrollEnabled else {
            return
        }

        // Calculate content offset from the context.
        let extra = scrollView.extra
        let offset = rebase(scrollView.contentOffset, from: scrollView)
        
        // Ignore when offset not any change.
        let dy = offset.y - extra.contentOffset.y
        guard dy != 0 else {
            return
        }
        
        // Limit the minimum content offset when offset in the middle.
        var y = pinnedContentOffset.y + dy
        if isPinnedEnabled, offset.y > 0 {
            y = max(y, 0)
        }
        
        // Start linkage all emabed scrollViews.
        activingView = scrollView

        // Expr: pinned + (offset - extra.contentoffset)
        updateContentOffsetIfNeeded(.init(x: offset.x, y: y))
        
        // When the update is finished, it is forbidden.
        activingView = nil
        
        // Check whether need to clamping the adjustment pinned content offset.
        guard isPinnedEnabled, dy < 0 || offset.y < cachedContentSize.height else {
            return
        }
        
        // Clamping the pinned content offset.
        clamping(cachedContentOffset)
    }
    @objc
    fileprivate func updateContentOffsetStatusWithObserver(_ scrollView: UIScrollView) {
        // Checks whether the current state allows for scroll events to be update.
        guard !isLockedOffsetChanges, isScrollEnabled, isPinnedEnabled else {
            return
        }

        // Process the state at the end of the gesture.
        switch scrollView.panGestureRecognizer.state {
        case .cancelled,
             .failed,
             .ended:
            // Calculate content offset and velocity for gesture recognizer.
            let offset = rebase(scrollView.contentOffset, from: scrollView)
            switch scrollView.panGestureRecognizer.velocity(in: nil).y {
            case let velocity where velocity >= 250:
                // Reopen
                guard cachedContentOffset.y > 0, offset.y >= cachedContentSize.height else {
                    return
                }

                // Perform changes with animation.
                animations(.init(cachedContentOffset.y / cachedContentSize.height)) {
                    self.setContentOffset(.zero,
                                          animated: true)
                }
                
                // Start the pinned.
                clamping(cachedContentOffset)
                
            case let velocity where velocity <= 50:
                guard cachedContentOffset.y > 0, offset.y >= cachedContentSize.height else {
                    return
                }
                
                // Perform changes with animation.
                animations(.init((cachedContentSize.height - cachedContentOffset.y) / cachedContentSize.height)) {
                    self.setContentOffset(.init(x: 0, y: self.cachedContentSize.height),
                                          animated: true)
                }

                // Cancel the pinned.
                clamping(nil)

            default:
                logger.debug?.write("???", scrollView.panGestureRecognizer.velocity(in: nil), offset, cachedContentSize)
                break
            }
            
        default:
            break
        }
    }

    fileprivate func updateContentInsets(_ offset: CGVector) {
        // When user disable automatically adjusts options, ignore.
        guard automaticallyAdjustsEmbeddedViewInset, offset != .zero else {
            return
        }
        // Synchronize all changes to all embed scrollViews.
        performWithoutContentChanges {
            scrollViews.forEach {
                updateContentInsets(offset, for: $0)
            }
        }
    }
    fileprivate func updateContentInsets(_ offset: CGVector, for extra: UIScrollView.Extra) {
        // When setting up `contentInset`, need to readjust the `contentOffset`.
        let minHeight = topLayoutGuide.layoutFrame.height
        let contentOffset = extra.scrollView.contentOffset
        
        // The `XCParallaxingView` only needs handle the `top` of the `contentInset` for scrollView..
        extra.contentInset.top += offset.dy
        
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
        extra.scrollView.contentOffset.y = min(contentOffset.y - offset.dy, -minHeight)
    }
    
    fileprivate func updateContentIndicatorInsets(_ offset: CGVector) {
        // When user disable automatically adjusts options, ignore.
        guard automaticallyAdjustsEmbeddedViewInset, offset != .zero else {
            return
        }
        // Synchronize all changes to all embed scrollViews.
        performWithoutContentChanges {
            scrollViews.forEach {
                updateContentIndicatorInsets(offset, for: $0)
            }
        }
    }
    fileprivate func updateContentIndicatorInsets(_ offset: CGVector, for extra: UIScrollView.Extra) {
        // The indicator must to follow a content offset to move.
        extra.scrollIndicatorInsets.top += offset.dy
    }
    
    fileprivate func updateContentDecorationsInsets(_ offset: CGPoint, for extra: UIScrollView.Extra) {
        // The decoration must to follow a content offset to move.
        extra.scrollDecorationsInsets.top = min(offset.y, 0)
    }
    fileprivate func updateContentDecorationsInsetsIfNeeded() {
        // When user disable automatically adjusts options, ignore.
        guard automaticallyAdjustsEmbeddedViewInset else {
            return
        }
        // Fix pinned view origin error issue.
        performWithoutContentChanges {
            scrollViews.forEach {
                updateContentDecorationsInsets(.init(x: 0, y: -cachedContentOffset.y), for: $0)
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
        insertSubview(newValue, aboveSubview: presentedView)
        
        // Restore header view constraints.
        NSLayoutConstraint.activate(
            [
                newValue.topAnchor.constraint(equalTo: topLayoutGuide.topAnchor),
                newValue.leadingAnchor.constraint(equalTo: leadingAnchor),
                newValue.trailingAnchor.constraint(equalTo: trailingAnchor),
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
                newValue.topAnchor.constraint(equalTo: intrinsicLayoutGuide.topAnchor, constant: contentInset.top).save(to: &insetTopLayoutConstraint),
                newValue.leadingAnchor.constraint(equalTo: intrinsicLayoutGuide.leadingAnchor, constant: contentInset.left).save(to: &insetLeftLayoutConstraint),
                newValue.trailingAnchor.constraint(equalTo: intrinsicLayoutGuide.trailingAnchor, constant: -contentInset.right).save(to: &insetRightLayoutConstraint),
                newValue.bottomAnchor.constraint(equalTo: intrinsicLayoutGuide.bottomAnchor, constant: -contentInset.bottom).save(to: &insetBottomLayoutConstraint)
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
        insertSubview(newValue, belowSubview: presentedView)
        
        // Restore footer view constraints.
        NSLayoutConstraint.activate(
            [
                newValue.topAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor),
                newValue.leadingAnchor.constraint(equalTo: presentingView.leadingAnchor),
                newValue.trailingAnchor.constraint(equalTo: presentingView.trailingAnchor),
                newValue.heightAnchor.constraint(equalTo: bottomLayoutGuide.heightAnchor)
            ]
        )
    }
    
    fileprivate func updateSuperview(_ superview: UIView?) {
        // If the superview is changes, reattach it.
        guard superview !== self.superview else {
            return
        }
        
        // First remove container view from view controller,
        // so that the constraint is automatically remove.
        removeFromSuperview()
        
        // If superview is nil, it is only remove without adding.
        guard let superview = superview else {
            return
        }
        
        // And then add the container view to view controller.
        superview.addSubview(self)
        
        // Finally restore the view controller constraints.
        NSLayoutConstraint.activate(
            [
                topAnchor.constraint(equalTo: superview.topAnchor).save(to: &offsetLayoutConstraint),
                leadingAnchor.constraint(equalTo: superview.leadingAnchor),
                widthAnchor.constraint(equalTo: superview.widthAnchor)
            ]
        )
        
        // Trying to restore subview.
        headerView.map { updateSubview(forHeaderView: $0) }
        contentView.map { updateSubview(forContentView: $0) }
        footerView.map { updateSubview(forFooterView: $0) }
    }
    @objc
    fileprivate func updateSuperviewWithObserver(_ viewController: UIViewController) {
        // Apply superview for view controller.
        updateSuperview(viewController.view)
        
        // Apply top layout guide for view controller.
        // This constraint may be replaced by headerView.heightAnchor, so it cannot be required.
        NSLayoutConstraint.activate([viewController.topLayoutGuide.heightAnchor.constraint(equalTo: self.topLayoutGuide.heightAnchor).setPriority(.required - 1)])
        
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
    @objc
    fileprivate func updateSuperviewOffsetWithObserver(_ scrollView: UIScrollView) {
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
    
    @inline(__always) fileprivate func animations(_ duration: TimeInterval, animations: @escaping () -> Void) {
        UIView.animate(withDuration: 0.2 * duration + 0.05,
                       delay: 0,
                       options: .beginFromCurrentState,
                       animations:animations,
                       completion: nil)
    }
    
    @inline(__always) fileprivate func clamping(_ offset: CGPoint?) {
        // Update last content offset when pinned.
        pinnedContentOffset.y = max(offset?.y ?? 0, 0)
        
        // Update content offset when pinned.
        scrollViews.forEach {
            // If the offset is nil, reset all pinned properties.
            if offset == nil {
                $0.contentOffset.y = 0
                return
            }
            $0.contentOffset.y = max(rebase($0.scrollView.contentOffset, from: $0.scrollView).y, 0)
        }
    }

    @inline(__always) fileprivate func adjusted(_ scrollView: UIScrollView) -> Bool {
        if #available(iOS 11.0, *) {
            // Each scrollView can have a different content inset adjustment behavior after iOS 11+.
            if scrollView.contentInsetAdjustmentBehavior == .never {
                return false
            }
            return true
        }
        
        // In iOS 10, when there no using navigation controller, the `contentInsets` of `scrollView` is zero,
        // But the `contentInsets` of `scrollView` is normal when has navigation controller.
        if viewController?.navigationController == nil {
            return false
        }
        
        return viewController?.automaticallyAdjustsScrollViewInsets ?? false
    }
    
    @inline(__always) fileprivate func rebase(_ offset: CGPoint, from scrollView: UIScrollView) -> CGPoint {
        // In iOS11, must use `adjustedContentInset`
        if #available(iOS 11.0, *) {
            return .init(x: offset.x + scrollView.adjustedContentInset.left, y: offset.y + scrollView.adjustedContentInset.top)
        }
        return .init(x: offset.x + scrollView.contentInset.left, y: offset.y + scrollView.contentInset.top)
    }
    @inline(__always) fileprivate func rebase(_ offset: CGPoint, to scrollView: UIScrollView) -> CGPoint {
        let edg: UIEdgeInsets
        
        // In iOS11, must use `adjustedContentInset`
        if #available(iOS 11.0, *) {
            edg = scrollView.adjustedContentInset
        } else {
            edg = scrollView.contentInset
        }
        
        return .init(x: max(-edg.left + offset.x, -edg.left), y: max(-edg.top + offset.y, -edg.top))
    }
    @inline(__always) fileprivate func rebase(_ offset: CGFloat) -> CGFloat {
        // Hovering over the top.
        var newValue = CGPoint(x: 0, y: min(offset, intrinsicLayoutGuide.frame.height))
        
        // If a bounce is prohibited, limit the maximum.
        if !isBounces {
            newValue.y = max(newValue.y, 0)
        }
        
        // Apply for delegate.
        delegate?.parallaxingView?(self, willChangeOffset: .init(x: 0, y: offset), targetContentOffset: &newValue)
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
        self.intrinsicLayoutGuide.isUserInteractionEnabled = false
        self.intrinsicLayoutGuide.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure the container view.
        self.isOpaque = true
        self.clipsToBounds = false
        self.backgroundColor = nil
        self.translatesAutoresizingMaskIntoConstraints = false
        
        self.addLayoutGuide(self.topLayoutGuide)
        self.addLayoutGuide(self.bottomLayoutGuide)
        
        self.addSubview(self.intrinsicLayoutGuide)
        self.addSubview(self.presentingView)

        self.addConstraints(
            [
                self.presentingView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor),
                self.presentingView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                self.presentingView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
                self.presentingView.bottomAnchor.constraint(equalTo: self.bottomLayoutGuide.topAnchor).setPriority(.required - 201),
                
                self.topLayoutGuide.topAnchor.constraint(equalTo: self.topAnchor),
                self.topLayoutGuide.widthAnchor.constraint(equalToConstant: 0),
                self.topLayoutGuide.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                self.topLayoutGuide.heightAnchor.constraint(equalToConstant: 0).setPriority(.required - 201),
                
                //self.intrinsicLayoutGuide.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor),
                self.intrinsicLayoutGuide.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                self.intrinsicLayoutGuide.trailingAnchor.constraint(equalTo: self.trailingAnchor),
                self.intrinsicLayoutGuide.bottomAnchor.constraint(equalTo: self.presentingView.bottomAnchor),
                
                self.bottomLayoutGuide.widthAnchor.constraint(equalToConstant: 0),
                self.bottomLayoutGuide.bottomAnchor.constraint(equalTo: self.bottomAnchor),
                self.bottomLayoutGuide.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                self.bottomLayoutGuide.heightAnchor.constraint(equalToConstant: 0).setPriority(.required - 201),
                
                self.presentingLayoutConstraint
            ]
        )
    }
    
    deinit {
        // Remove observer when view controller is set.
        self.viewController?.removeObserver(self, forKeyPath: "view")
        self.viewController = nil
        
        // Clean attached scroll view.
        self.scrollViews.forEach {
            self.unembed($0.scrollView)
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
    fileprivate var pinnedContentOffset: CGPoint = .zero

    fileprivate var isLockedOffsetChanges: Bool = false
    
    // If the cached content property has any changes, will trigger the update again.
    fileprivate var cachedContentSize: CGSize = .zero
    fileprivate var cachedContentSizeWithRaw: CGSize = .zero
    fileprivate var cachedContentOffset: CGPoint = .zero
    fileprivate var cachedContentOffsetWithRaw: CGPoint = .zero

    fileprivate let topLayoutGuide: UILayoutGuide = .init()
    fileprivate let bottomLayoutGuide: UILayoutGuide = .init()
    fileprivate let intrinsicLayoutGuide: UIView = .init()
    
    fileprivate var offsetLayoutConstraint: NSLayoutConstraint?
    fileprivate var presentingLayoutConstraint: NSLayoutConstraint
    
    fileprivate var insetTopLayoutConstraint: NSLayoutConstraint?
    fileprivate var insetLeftLayoutConstraint: NSLayoutConstraint?
    fileprivate var insetRightLayoutConstraint: NSLayoutConstraint?
    fileprivate var insetBottomLayoutConstraint: NSLayoutConstraint?

    fileprivate var scrollViews: Set<UIScrollView.Extra> = []
    fileprivate var activingView: UIView?
    fileprivate let presentingView: UIView = .init()

    // The current associated view controller.
    fileprivate unowned(unsafe) var viewController: UIViewController?
    
    // Provide a memory address that is available.
    fileprivate static var defaultKey: String = ""
    
    // Load all resolved dependencies.
    fileprivate static var resolvedDependencies: Void = {
        // Exchange the selector c implementations.
        @inline(__always) func exchangeImplementations(_ clazz: AnyClass?, _ sel1: String, _ sel2: String) {
            // Ignore when get instance method fail.
            if let clazz = clazz, let org = class_getInstanceMethod(clazz, Selector(sel1)), let new = class_getInstanceMethod(clazz, Selector(sel2)) {
                method_exchangeImplementations(org, new)
            }
        }
        exchangeImplementations(UITableView.self, "_contentInset", "__parallaxing_contentInset")
        exchangeImplementations(NSClassFromString("UITouchesEvent"), "touchesForView:", "__parallaxing_touchesForView:")
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
        for otherGestureRecognizer in firstGestureRecognizers + secondGestureRecognizers {
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
        // swiftlint:disable:next unused_setter_value
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
    
    // The gesture recognizers system will query view type.
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
        
        // Check the gesture recognizers type.
        let isFirstResponder = firstGestureRecognizers.contains(gestureRecognizer)
        
        // Check the gesture recognizers type has been locked.
        if !lockFirstResponder, isFirstResponder {
            lockFirstResponder = true
            
            // Cancel all non-first responders gesture recognizers.
            responsingGestureRecognizers.forEach { (otherGestureRecognizer, isFirstResponder) in
                if otherGestureRecognizer.state != .ended, otherGestureRecognizer.state != .cancelled, !isFirstResponder {
                    otherGestureRecognizer.state = .cancelled
                }
            }
        }
        
        // Record each gesture recognizers that responds.
        responsingGestureRecognizers.append((gestureRecognizer, isFirstResponder))
        
        // always allow to begin when the gesture recognizer is first.
        if responsingGestureRecognizers.count == 1 {
            return true
        }
        
        // If it is the first responder's gesture recognizers, always allow to begin.
        return isFirstResponder || !lockFirstResponder
    }
    
    // Tweak: The gesture will call this method to check the view hierarchy. (Work in iOS 13.1/13.2)
    @objc func _isEffectivelyDescendantOfViewForGestures(_ view: UIView) -> Bool {
        return true
    }
    
    fileprivate var lockFirstResponder: Bool = false
    
    fileprivate weak var hitedSuperview: UIView?
    fileprivate weak var hitedFirstResponder: UIView?
    fileprivate weak var hitedSecondResponder: UIView?
    
    fileprivate lazy var firstGestureRecognizers: [UIGestureRecognizer] = []
    fileprivate lazy var secondGestureRecognizers: [UIGestureRecognizer] = []
    fileprivate lazy var responsingGestureRecognizers: [(UIGestureRecognizer, Bool)] = []
    
    // Get the `panGestureRecognizer` runtime type of `UIScrollView` instance.
    fileprivate static let scrollViewPanGestureRecognizer = type(of: UIScrollView().panGestureRecognizer)
}


// Fix the `UIControl` does not respond to the issue.
fileprivate extension UIEvent {
    
    // Because we forwarding the touches event to gateView,
    // so UIButton can't using "touchesForView:" to query the touch.
    @objc(__parallaxing_touchesForView:)
    private dynamic func touchesForView$(_ view: UIView) -> Set<UITouch>? {
        // Because only `UIControl` has a issue, only need to process with it.
        let touches = touchesForView$(view)
        guard touches == nil, view is UIControl else {
            return touches
        }
        
        // Additional find in gateway view.
        for touch in allTouches ?? [] where view === (touch.view as? XCParallaxingGateView)?.hitedFirstResponder {
            return [touch]
        }
        return nil
    }
    
}

// Fix the `UITableView` pinned view origin error issue.
fileprivate extension UIScrollView {
    
    // The extra content for scroll view.
    class Extra: Hashable {
        
        // Owned scroll view for extra.
        unowned(unsafe) let scrollView: UIScrollView
        init(_ scrollView: UIScrollView) {
            self.scrollView = scrollView
        }
        
        /// Additional content offset.
        var contentOffset: CGPoint = .zero
        
        /// Additional content insets.
        var contentInset: UIEdgeInsets = .zero {
            didSet {
                var edg = scrollView.contentInset
                edg.top += contentInset.top - oldValue.top
                edg.left += contentInset.left - oldValue.left
                edg.right += contentInset.right - oldValue.right
                edg.bottom += contentInset.bottom - oldValue.bottom
                scrollView.contentInset = edg
            }
        }
        
        /// Additional indicator insets.
        var scrollIndicatorInsets: UIEdgeInsets = .zero {
            didSet {
                var edg = scrollView.scrollIndicatorInsets
                edg.top += scrollIndicatorInsets.top - oldValue.top
                edg.left += scrollIndicatorInsets.left - oldValue.left
                edg.right += scrollIndicatorInsets.right - oldValue.right
                edg.bottom += scrollIndicatorInsets.bottom - oldValue.bottom
                scrollView.scrollIndicatorInsets = edg
            }
        }
        
        /// Additional decorations insets.
        var scrollDecorationsInsets: UIEdgeInsets = .zero
        
        
        /// Hashes the essential components of this value by feeding them into the given hasher.
        func hash(into hasher: inout Hasher) {
            scrollView.hash(into: &hasher)
        }

        
        /// Complete the contents.
        static func == (lhs: Extra, rhs: Extra) -> Bool {
            return lhs.scrollView == rhs.scrollView
        }

        /// Extra associated key for scroll view.
        static var extraKey: String = ""
    }
    
    // Record the extra content for scroll view.
    @inline(__always) var extra: Extra {
        if let extra = objc_getAssociatedObject(self, &Extra.extraKey) as? Extra {
            return extra
        }
        let extra = Extra(self)
        objc_setAssociatedObject(self, &Extra.extraKey, extra, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return extra
    }

    // In `UIScrollView` the `contentInset` modification, will leads to `UITableView` the pinned view origin error.
    // This issue resolved by adding `includingDecorations`, But this is a undocumented API, it work in iOS 0 - iOS 13(or more).
    @objc(__parallaxing_contentInset)
    private dynamic func contentInset$() -> UIEdgeInsets {
        var newContentInsets = contentInset$()
        let scrollDecorationsInsets = extra.scrollDecorationsInsets
        newContentInsets.top += scrollDecorationsInsets.top
        newContentInsets.left += scrollDecorationsInsets.left
        newContentInsets.right += scrollDecorationsInsets.right
        newContentInsets.bottom += scrollDecorationsInsets.bottom
        return newContentInsets
    }
    
}


/// Quickly setup.
fileprivate extension NSLayoutConstraint {
    @inline(__always) func setPriority(_ priority: UILayoutPriority) -> NSLayoutConstraint {
        self.priority = priority
        return self
    }
    @inline(__always) func save(to constraint: inout NSLayoutConstraint?) -> NSLayoutConstraint {
        constraint = self
        return self
    }
}

/// This copied codes for maintain components independence.
/// The extension `NSObjectProtocol` protocol does not generate category load code.
fileprivate extension NSObjectProtocol {
    
    /// Dynamic inheritance.
    @discardableResult
    @inline(__always) func inheritClass(_ name: String, methods: ((AnyClass) -> Void)? = nil) -> Self {
        // If the class have created, use it.
        if let clazz = NSClassFromString(name) {
            // If you have inherited it, ignore it.
            if !isKind(of: clazz) {
                object_setClass(self, clazz)
            }
            return self
        }
        
        // Creating a dynamic class.
        if let clazz = objc_allocateClassPair(type(of: self), name, 0) {
            // Reigster and add methods in dymamic class.
            objc_registerClassPair(clazz)
            methods?(clazz)
            object_setClass(self, clazz)
        }
        
        return self
    }
    
    /// Add a destruct observer.
    @inline(__always) func addDestructObserver(_ callback: @escaping () -> Void) {
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
                let dealloc: @convention(block) (Unmanaged<NSMutableArray>) -> Void = {
                    // Call each registered callback.
                    $0.takeUnretainedValue().forEach {
                        ($0 as? (() -> Void))?()
                    }
                    
                    // Must call `dealloc` for `superclass`, otherwise will occur memory leaks.
                    let sel = NSSelectorFromString("dealloc")
                    if let imp = class_getMethodImplementation($0.takeUnretainedValue().superclass, sel) {
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
