//
//  T.swift
//  NetEaseMusic
//
//  Created by SAGESSE on 2019/6/6.
//  Copyright © 2019 SAGESSE. All rights reserved.
//

import UIKit

//internal class XCParallaxaView: UIView {
//    
//    internal override init(frame: CGRect) {
//        super.init(frame: frame)
//        self.prepare()
//    }
//    
//    internal required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        self.prepare()
//    }
//    
//    deinit {
//        // Clean attached scroll view.
//        embeddedScrollViews.forEach {
//            $0.removeObserver(self, forKeyPath: "contentOffset")
//        }
//        embeddedScrollViews = []
//        unembeddedScrollViews = []
//    }
//    
//    // MARK: -
//    
//    internal var contentView: UIView? {
//        willSet {
//            // If the view nothing changes, ignore it.
//            guard newValue != contentView else {
//                return
//            }
//            
//            // Remove the constraint only if the view is added.
//            if let oldValue = contentView {
//                // Remove view will clean all constraints.
//                oldValue.removeFromSuperview()
//                cropView.isHidden = true
//            }
//            
//            // Only need to add the constraint when the view exists.
//            guard let newValue = newValue else {
//                return
//            }
//            
//            // Add container view to view.
//            newValue.removeFromSuperview()
//            newValue.translatesAutoresizingMaskIntoConstraints = false
//            cropView.isHidden = false
//            cropView.addSubview(newValue)
//            
//            // Add view will recreate all constraints.
//            addConstraints(
//                [
//                    newValue.leftAnchor.constraint(equalTo: referenceView.leftAnchor),
//                    newValue.rightAnchor.constraint(equalTo: referenceView.rightAnchor),
//                    newValue.bottomAnchor.constraint(equalTo: referenceView.bottomAnchor),
//                    
//                    // Must associate the height constraint into placeholder view.
//                    newValue.heightAnchor.constraint(lessThanOrEqualTo: placeholderView.heightAnchor),
//                ]
//            )
//        }
//    }
//    
//    internal var containerView: UIView? {
//        willSet {
//            // If the view nothing changes, ignore it.
//            guard newValue != containerView else {
//                return
//            }
//            
//            // Remove the constraint only if the view is added.
//            if let oldValue = containerView {
//                // Remove view will clean all constraints.
//                oldValue.removeFromSuperview()
//                referenceView.isHidden = true
//            }
//            
//            // Only need to add the constraint when the view exists.
//            guard let newValue = newValue else {
//                return
//            }
//            
//            // Add container view to view.
//            newValue.removeFromSuperview()
//            newValue.translatesAutoresizingMaskIntoConstraints = false
//            newValue.setNeedsLayout()
//            referenceView.isHidden = false
//            referenceView.insertSubview(newValue, at: 0)
//            
//            // Add view will recreate all constraints.
//            setNeedsLayout()
//            addConstraints(
//                [
//                    newValue.leftAnchor.constraint(equalTo: referenceView.leftAnchor),
//                    newValue.rightAnchor.constraint(equalTo: referenceView.rightAnchor),
//                    newValue.bottomAnchor.constraint(equalTo: referenceView.bottomAnchor),
//                    
//                    // Must associate the height constraint into placeholder view.
//                    newValue.heightAnchor.constraint(lessThanOrEqualTo: placeholderView.heightAnchor),
//                ]
//            )
//        }
//    }
//    
//    internal var backgroundView: UIView? {
//        willSet {
//            // If the view nothing changes, ignore it.
//            guard newValue != backgroundView else {
//                return
//            }
//            
//            // Remove the constraint only if the view is added.
//            if let oldValue = backgroundView {
//                // Remove view will clean all constraints.
//                oldValue.removeFromSuperview()
//            }
//            
//            // Only need to add the constraint when the view exists.
//            guard let newValue = newValue else {
//                return
//            }
//            
//            // Add container view to view.
//            newValue.removeFromSuperview()
//            newValue.translatesAutoresizingMaskIntoConstraints = false
//            newValue.setNeedsLayout()
//            insertSubview(newValue, at: 0)
//            
//            // Add view will recreate all constraints.
//            addConstraints(
//                [
//                    newValue.topAnchor.constraint(equalTo: topLayoutGuide.topAnchor).priority(to: .required - 10),
//                    newValue.leftAnchor.constraint(equalTo: leftAnchor),
//                    newValue.rightAnchor.constraint(equalTo: rightAnchor),
//                    newValue.bottomAnchor.constraint(equalTo: bottomAnchor),
//                ]
//            )
//        }
//    }
//    
//    
//    // MARK: -
//    
//    
//    internal var isBounces: Bool = true
//    
//    internal var isScrollEnabled: Bool = true
//    
//    
//    internal var contentSize: CGSize {
//        set { return updateContentSizeIfNeeded(newValue) }
//        get { return cachedContentSize }
//    }
//    
//    internal var contentOffset: CGPoint {
//        set { return updateContentOffsetIfNeeded(newValue) }
//        get { return cachedContentOffset }
//    }
//    
//    internal var contentInsets: UIEdgeInsets {
//        set {
//            // If the content inset is nothing has changed, ignore.
//            guard newValue != cachedContentInsets else {
//                return
//            }
//            
//            let dy = newValue.top - cachedContentInsets.top + newValue.bottom - cachedContentInsets.bottom
//            
//            // Update edge insets for top and bottom.
//            offsetTopLayoutConstraint?.constant -= newValue.top - cachedContentInsets.top
//            offsetBottomLayoutConstraint?.constant += newValue.bottom - cachedContentInsets.bottom
//            
//            // Update all inner margin indentation at the same time.
//            performWithoutContentChanges {
//                embeddedScrollViews.forEach {
//                    // Update the contentInset and restore contentOffset.
//                    $0.contentInset.top -= dy
//                    $0.scrollIndicatorInsets.top -= dy
//                }
//            }
//            
//            // Update current content inset.
//            cachedContentInsets = newValue
//        }
//        get {
//            return cachedContentInsets
//        }
//    }
//    
//    
//    internal var minimumContentSize: CGSize = .zero {
//        willSet {
//            guard newValue != minimumContentSize, embeddedViewController != nil else {
//                return
//            }
//            embeddedScrollViews.first.map {
//                updateContentOffsetWithObserver($0)
//            }
//        }
//    }
//    
//    
//    // MARK: -
//    
//    
//    /// Embed into a view controller.
//    internal func embed(_ viewController: UIViewController) {
//        // The view controller must be change.
//        guard viewController !== embeddedViewController else {
//            return
//        }
//        
//        // Uninstall the view controller.
//        embeddedViewController.map {
//            unembed($0)
//        }
//        
//        // Install the view controller.
//        embeddedViewController = viewController
//        embeddedViewController?.addObserver(self, forKeyPath: "view", options: .new,  context: .init(mutating: sel_getName(#selector(updateSuperviewWithObserver(_:)))))
//        
//        // Restore all pending embedded scrollviews.
//        performWithoutContentChanges {
//            unembeddedScrollViews = unembeddedScrollViews.filter {
//                (embed($0), false).1
//            }
//        }
//        
//        // The view must to been loaded.
//        guard viewController.isViewLoaded else {
//            return
//        }
//        
//        // Update superview if needed.
//        updateSuperviewWithObserver(viewController)
//    }
//    
//    /// Unembed from view controller.
//    internal func unembed(_ viewController: UIViewController) {
//        // The view controller must embed.
//        guard viewController === embeddedViewController else {
//            return
//        }
//        
//        // Setup current emabed view controller.
//        embeddedViewController?.removeObserver(self, forKeyPath: "view")
//        embeddedViewController = nil
//        
//        // Unembed all display scroll view.
//        performWithoutContentChanges {
//            unembeddedScrollViews = embeddedScrollViews.filter {
//                (unembed($0), true).1
//            }
//            embeddedScrollViews.removeAll()
//        }
//        
//        // Reomve parallax item form view
//        removeFromSuperview()
//    }
//    
//    
//    /// Embed a scroll view into parallaxa view.
//    internal func embed(_ scrollView: UIScrollView) {
//        // If view controller is not embedded, add scroll view to unembed queue.
//        guard embeddedViewController != nil else {
//            unembeddedScrollViews.append(scrollView)
//            return
//        }
//        
//        // If the scroll view is already attached, can't be added again.
//        guard !embeddedScrollViews.contains(scrollView) else {
//            return
//        }
//        
//        embeddedScrollViews.append(scrollView)
//        scrollView.addObserver(self,
//                               forKeyPath: "contentOffset",
//                               options: .new,
//                               context: .init(mutating: sel_getName(#selector(updateContentOffsetWithObserver(_:)))))
//        
//        // Apply changes for parallax view.
//        performWithoutContentChanges {
//            // Must restore contentOffset when set contentInset.
//            let oldContentOffset = scrollView.contentOffset
//            
//            scrollView.contentInset.top += absoluteContentHeight
//            scrollView.scrollIndicatorInsets.top += absoluteContentHeight - cachedContentOffset.y
//            scrollView.contentOffset.y = oldContentOffset.y - absoluteContentHeight + cachedContentOffset.y
//        }
//    }
//    
//    /// Unembed a scroll view from parallaxa view.
//    internal func unembed(_ scrollView: UIScrollView) {
//        
//        // Remove this scroll view in the unembed queue.
//        if let index = unembeddedScrollViews.firstIndex(of: scrollView) {
//            unembeddedScrollViews.remove(at: index)
//        }
//        
//        // If the scroll view is not attached, no need to remove.
//        guard let index = embeddedScrollViews.firstIndex(of: scrollView) else {
//            return
//        }
//        
//        embeddedScrollViews.remove(at: index)
//        scrollView.removeObserver(self, forKeyPath: "contentOffset")
//        
//        // Restore changes for parallax view.
//        performWithoutContentChanges {
//            // Update content inset and indicator inset.
//            scrollView.contentInset.top -= absoluteContentHeight
//            scrollView.scrollIndicatorInsets.top -= absoluteContentHeight - cachedContentOffset.y
//        }
//    }
//    
//    
//    internal func performWithoutContentChanges(_ actionsWithoutContentChanges: () -> ()) {
//        // Because this method is only executed on the main thread, there is no need to lock it.
//        let oldValue = allowsReceiveObservering
//        allowsReceiveObservering = false
//        actionsWithoutContentChanges()
//        allowsReceiveObservering = oldValue
//    }
//    
//    // MARK: -
//    
//    
//    internal override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
//        // Compute the current hit view.
//        guard let view = super.hitTest(point, with: event) else {
//            return nil
//        }
//        
//        // If a view blank area is hit, ignore the touch event for this view.
//        guard view !== self, view !== cropView, view !== referenceView else {
//            return nil
//        }
//        
//        return view
//    }
//    
//    internal override func willMove(toSuperview newSuperview: UIView?) {
//        super.willMove(toSuperview: newSuperview)
//        
//        // Ignore for superview is not change.
//        guard superview != newSuperview else {
//            return
//        }
//        
//        // In iOS 11, the `topLayoutGuide` display error of UITableViewConroller has been solved.
//        if #available(iOS 11.0, *) {
//            return
//        }
//        
//        // Remove observer for old superview.
//        if let scrollView = superview as? UIScrollView {
//            scrollView.removeObserver(self, forKeyPath: "contentOffset")
//        }
//        
//        // Add observer for new superview.
//        if let scrollView = newSuperview as? UIScrollView {
//            scrollView.addObserver(self,
//                                   forKeyPath: "contentOffset",
//                                   options: [.initial, .new],
//                                   context: .init(mutating: sel_getName(#selector(updateSuperviewOffsetWithObserver(_:)))))
//        }
//    }
//    
//    internal override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
//        // Automatically perform to the specified method for context.
//        context.map {
//            _ = perform(sel_registerName($0.assumingMemoryBound(to: Int8.self)), with: object, with: change)
//        }
//    }
//    
//    internal override func layoutSubviews() {
//        super.layoutSubviews()
//        
//        // Check that the height of the added view has changed.
//        if cachedPlaceholderSize != placeholderView.bounds.size {
//            cachedPlaceholderSize = placeholderView.bounds.size
//            
//            // Force an update of container view layout.
//            containerView?.setNeedsLayout()
//            containerView?.layoutIfNeeded()
//            
//            // Force an update of content view layout.
//            contentView?.setNeedsLayout()
//            contentView?.layoutIfNeeded()
//        }
//        
//        // Calculate the available height of the content.
//        let bar = topLayoutGuide.layoutFrame.height
//        let content = contentView?.frame.height.advanced(by: bar) ?? 0
//        let container = containerView?.frame.height ?? 0
//        
//        // Get the maximum height.
//        let contentSize = CGSize(width: bounds.width, height: max(max(bar, content), container))
//        guard contentSize != referenceView.bounds.size else {
//            return
//        }
//        
//        // When content size changes occur, they need to be updated..
//        if contentSize.height != referenceView.bounds.height {
//            estimatedLayoutConstraint?.constant = contentSize.height
//        }
//        
//        // If the content size is changes, all the margins are automatically updated.
//        updateContentSizeIfNeeded(.init(width: contentSize.width, height: max(contentSize.height - bar, 0)))
//    }
//    
//    
//    // MARK: -
//    
//    @nonobjc fileprivate func updateContentSizeIfNeeded(_ newContentSize: CGSize) {
//        // Calculation of offset.
//        let dx = newContentSize.width - cachedContentSize.width
//        let dy = newContentSize.height - cachedContentSize.height
//        
//        // Only update when the offset is changed.
//        guard dx != 0 || dy != 0 else {
//            return;
//        }
//        
//        // Cache content size to determine whether the next update is valid.
//        cachedContentSize = newContentSize
//        
//        // The UI is updated only when automatic updates are turned on.
//        guard allowsReceiveUpdating else {
//            return
//        }
//        
//        updateContentInsets(.init(dx: dx, dy: dy))
//        updateContentIndicatorInsets(.init(dx: dx, dy: dy))
//        
//        // When the content size has been changes, the content offset may be invalid,
//        // so the needs to be recalculated content offset.
//        embeddedScrollViews.first.map {
//            updateContentOffsetWithObserver($0)
//        }
//    }
//    
//    @nonobjc fileprivate func updateContentOffset(_ offset: CGVector) {
//        // Only update when the offset is changed.
//        guard offset != .zero else {
//            return
//        }
//        //        logger.trace?.write("\(offsetTopLayoutConstraint?.constant.advanced(by: -offset.dy) ?? 0)/\(offset.dy)")
//        
//        // Synchronize content offset changed results to User Interface.
//        offsetTopLayoutConstraint?.constant -= offset.dy
//        
//        //        // Update content with progress
//        //        [self updateProgress:self.contentOffset.y / MAX(self.contentSize.height, 1)];
//        //
//        //        // Joint change is automatic synchronization when multiple `scrollView` exists.
//        //        if (!self.allowsAutomaticallyLinking || self.scrollViews.count <= 1) {
//        //            return;
//        //        }
//        //
//        //        // Synchronizing all scroll views.
//        //        [self performWithoutContentChanges:^{
//        //            [self.scrollViews enumerateObjectsUsingBlock:^(UIScrollView* scrollView, NSUInteger idx, BOOL * _Nonnull stop) {
//        //            CGPoint org = scrollView.contentOffset;
//        //            UIEdgeInsets edg = scrollView.contentInset;
//        //
//        //            // In iOS11, must use `adjustedContentInset`
//        //            if (@available(iOS 11.0, *)) {
//        //            edg = scrollView.adjustedContentInset;
//        //            }
//        //
//        //            CGFloat offset = fmax(self.contentOffset.y - edg.top, -edg.top);
//        //
//        //            // If `contentOffset` does not change, it is ignored
//        //            if (__fequ(offset, org.y)) {
//        //            return ;
//        //            }
//        //
//        //            // If `scrollView` is not in the active area, it is ignored
//        //            if (round(org.y) < round(-edg.top)) {
//        //            return;
//        //            }
//        //            //NSLog(@"%zd %lf/%lf/%+lf", idx, offset, org.y, offset - org.y);
//        //
//        //            scrollView.contentOffset = CGPointMake(0, offset);
//        //            }];
//        //
//        //            // Notify segmentingContainer updates
//        //            if ([self.externalreferenceView respondsToSelector:_cmd]) {
//        //            [self.externalreferenceView updateContentOffset:offset];
//        //            }
//        //            }];
//    }
//    
//    @nonobjc fileprivate func updateContentOffsetIfNeeded(_ offset: CGPoint) {
//        // A new content offset is generated.
//        var newContentOffset = offset
//        
//        // Hovering over the top.
//        newContentOffset.x = min(newContentOffset.x, max(absoluteContentWidth - minimumContentSize.width, 0))
//        newContentOffset.y = min(newContentOffset.y, max(absoluteContentHeight - minimumContentSize.height, 0))
//        
//        // If a bounce is prohibited, limit the maximum.
//        if !isBounces {
//            newContentOffset.x = max(newContentOffset.x, cachedContentInsets.left)
//            newContentOffset.y = max(newContentOffset.y, cachedContentInsets.top)
//        }
//        
//        // Calculation of offset.
//        let dx = newContentOffset.x - cachedContentOffset.x
//        let dy = newContentOffset.y - cachedContentOffset.y
//        
//        // Ignore update events when content offset is no change.
//        guard dy != 0 else {
//            return
//        }
//        
//        // Cache content offset to determine whether the next update is valid.
//        cachedContentOffset = newContentOffset
//        
//        // The UI is updated only when automatic updates are turned on.
//        guard allowsReceiveUpdating else {
//            return
//        }
//        
//        updateContentOffset(.init(dx: dx, dy: dy))
//        updateContentIndicatorInsets(.init(dx: -dx, dy: -dy))
//    }
//    
//    
//    @nonobjc fileprivate func updateContentInsets(_ offset: CGVector) {
//        // Only update when the offset is changed.
//        guard offset != .zero else {
//            return
//        }
//        logger.trace?.write(offset, cachedContentSize)
//        
//        // Update all inner margin indentation at the same time.
//        performWithoutContentChanges {
//            embeddedScrollViews.forEach {
//                updateContentInsets(offset, for: $0)
//            }
//        }
//    }
//    
//    @nonobjc fileprivate func updateContentInsets(_ offset: CGVector, for scrollView: UIScrollView) {
////        // When setting up `contentInset`, need to readjust the `contentOffset`.
////        let minHeight = topLayoutGuide.layoutFrame.height + minimumContentSize.height
////        let contentOffset = scrollView.contentOffset
//        
//        // Only update contentInset the top.
//        scrollView.contentInset.top += offset.dy
//        
////        // If the new contentOffset is not any change, don’t restore contentOffset.
////        // example:
////        //   -388 - 40 = -428 O/O/A
////        //   -388 + 40 = -348 O/O/D
////        //   -132 - 40 = -172 O/O/A
////        //   -132 + 40 = -92  X/X/D
////        //   -92  - 40 = -132 X/X/A
////        //   -88  - 40 = -128 X/X/A
////        //   -112 - 40 = -152 O/X/A
////        //   -152 + 40 = -112 X/O/D
////        guard contentOffset.y < -minHeight || contentOffset.y - offset.dy < -minHeight else {
////            return
////        }
////
////        // Sometimes contentOffset added too many offset, so it needs to be limit.
////        scrollView.contentOffset.y = min(contentOffset.y - offset.dy, -minHeight)
//    }
//    
//    @nonobjc fileprivate func updateContentIndicatorInsets(_ offset: CGVector) {
//        // Only update when the offset is changed.
//        guard offset != .zero else {
//            return
//        }
//        //logger.trace?.write(offset, contentOffset, contentSize)
//        
//        // Update all inner margin indentation at the same time.
//        performWithoutContentChanges {
//            embeddedScrollViews.forEach {
//                updateContentIndicatorInsets(offset, for: $0)
//            }
//        }
//    }
//    
//    @nonobjc fileprivate func updateContentIndicatorInsets(_ offset: CGVector, for scrollView: UIScrollView) {
//        // Update indicator insets in scrollView.
//        scrollView.scrollIndicatorInsets.top += offset.dy
//    }
//    
//    
//    @objc fileprivate func updateContentOffsetWithObserver(_ scrollView: UIScrollView) {
//        // Checks whether the current state allows for scroll events to be update.
//        guard allowsReceiveObservering, isScrollEnabled else {
//            return
//        }
//        
//        let edg: UIEdgeInsets
//        let offset: CGPoint = scrollView.contentOffset
//        
//        // In iOS11, must use `adjustedContentInset`
//        if #available(iOS 11.0, *) {
//            edg = scrollView.adjustedContentInset
//        } else {
//            edg = scrollView.contentInset
//        }
//        
//        // Only in the manual operation only requires synchronization
//        allowsAutomaticallyLinking = scrollView.isDragging || scrollView.isDecelerating
//        
//        // Automatic update content offset.
//        updateContentOffsetIfNeeded(.init(x: offset.x + edg.left, y: offset.y + edg.top))
//        
//        // When the update is finished, it is forbidden.
//        allowsAutomaticallyLinking = false
//    }
//    
//    @objc fileprivate func updateSuperviewWithObserver(_ viewController: UIViewController) {
//        // If superview doesn't change, ignore it.
//        guard viewController.view !== superview else {
//            return
//        }
//        
//        // Configure the container view constraints.
//        let topLayoutConstraints = [
//            viewController.topLayoutGuide.topAnchor.constraint(equalTo: topLayoutGuide.topAnchor).save(to: &topLayoutConstraint),
//            viewController.topLayoutGuide.heightAnchor.constraint(equalTo: topLayoutGuide.heightAnchor).priority(to: .required - 1),
//            
//            viewController.view.leftAnchor.constraint(equalTo: leftAnchor).save(to: &leftLayoutConstraint),
//            viewController.view.widthAnchor.constraint(equalTo: widthAnchor),
//        ]
//        
//        // Removing the view resets all constraints.
//        removeFromSuperview()
//        viewController.view.addSubview(self)
//        
//        // Activate the container view constraints.
//        topLayoutConstraints.forEach {
//            $0.isActive = true
//        }
//    }
//    
//    /// Keep view origin position in superview.
//    @objc fileprivate func updateSuperviewOffsetWithObserver(_ scrollView: UIScrollView) {
//        
//        // Update top constraint for content offset y is changed.
//        if scrollView.contentOffset.y != topLayoutConstraint?.constant {
//            topLayoutConstraint?.constant = -scrollView.contentOffset.y
//        }
//        
//        // Update top constraint for content offset x is changed.
//        if scrollView.contentOffset.x != leftLayoutConstraint?.constant {
//            leftLayoutConstraint?.constant = -scrollView.contentOffset.x
//        }
//    }
//    
//    
//    // MARK: -
//    
//    
//    fileprivate func prepare() {
//        
//        // Configure internal objectes symbol.
//        signifying(cropView, "XCParallaxaCropView")
//        signifying(referenceView, "XCParallaxaReferenceView")
//        signifying(placeholderView, "XCParallaxaPlaceholderView")
//        signifying(topLayoutGuide, "XCParallaxaTopLayoutGuide")
//        
//        // Configure parallaxa view.
//        translatesAutoresizingMaskIntoConstraints = false
//        
//        // When the view changes, container view cannot sense this change, so need a placeholder view to actively update the layout.
//        placeholderView.isHidden = true
//        placeholderView.isUserInteractionEnabled = false
//        placeholderView.translatesAutoresizingMaskIntoConstraints = false
//        
//        // Configure the reference view.
//        referenceView.isHidden = true
//        referenceView.translatesAutoresizingMaskIntoConstraints = false
//        
//        // Configure the crop view.
//        cropView.isHidden = true
//        cropView.clipsToBounds = true
//        cropView.backgroundColor = .clear
//        cropView.translatesAutoresizingMaskIntoConstraints = false
//        
//        // Setup container subviews.
//        addSubview(placeholderView)
//        addSubview(referenceView)
//        addSubview(cropView)
//        
//        // Setup container view layout guide.
//        addLayoutGuide(topLayoutGuide)
//        
//        // Setup container view constraints.
//        addConstraints(
//            [
//                topLayoutGuide.topAnchor.constraint(equalTo: topAnchor),
//                topLayoutGuide.leftAnchor.constraint(equalTo: leftAnchor),
//                topLayoutGuide.widthAnchor.constraint(equalToConstant: 0),
//                topLayoutGuide.heightAnchor.constraint(equalToConstant: 0).priority(to: .defaultLow - 1),
//                
//                placeholderView.leftAnchor.constraint(equalTo: leftAnchor),
//                placeholderView.rightAnchor.constraint(equalTo: rightAnchor),
//                placeholderView.bottomAnchor.constraint(equalTo: referenceView.bottomAnchor),
//                placeholderView.heightAnchor.constraint(equalToConstant: 0).priority(to: .init(1)),
//                
//                referenceView.topAnchor.constraint(equalTo: topAnchor).save(to: &offsetTopLayoutConstraint),
//                referenceView.leftAnchor.constraint(equalTo: leftAnchor),
//                referenceView.rightAnchor.constraint(equalTo: rightAnchor),
//                referenceView.bottomAnchor.constraint(equalTo: bottomAnchor).save(to: &offsetBottomLayoutConstraint),
//                referenceView.heightAnchor.constraint(equalToConstant: 0).priority(to: .required - 1).save(to: &estimatedLayoutConstraint),
//                
//                cropView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
//                cropView.leftAnchor.constraint(equalTo: leftAnchor),
//                cropView.rightAnchor.constraint(equalTo: rightAnchor),
//                cropView.bottomAnchor.constraint(equalTo: bottomAnchor).priority(to: .required - 5),
//            ]
//        )
//    }
//    
//    fileprivate func signifying(_ obj: AnyObject, _ signature: String) {
//        let name = NSStringFromClass(type(of: self)).replacingOccurrences(of: "XCParallaxaView", with: "\(signature)")
//        
//        if let newClass = NSClassFromString(name) {
//            object_setClass(obj, newClass)
//            return
//        }
//        
//        if let newClass = objc_allocateClassPair(type(of: obj) as AnyClass, name, 0) {
//            objc_registerClassPair(newClass)
//            object_setClass(obj, newClass)
//            return
//        }
//    }
//    
//    
//    // MARK: -
//    
//    
//    private var topLayoutConstraint: NSLayoutConstraint?
//    private var leftLayoutConstraint: NSLayoutConstraint?
//    private var estimatedLayoutConstraint: NSLayoutConstraint?
//    
//    private var offsetTopLayoutConstraint: NSLayoutConstraint?
//    private var offsetBottomLayoutConstraint: NSLayoutConstraint?
//    
//    private var embeddedScrollViews: Array<UIScrollView> = []
//    private var unembeddedScrollViews: Array<UIScrollView> = []
//    
//    private let cropView: UIView = .init()
//    private let referenceView: UIView = .init()
//    private let placeholderView: UIView = .init()
//    
//    private let topLayoutGuide: UILayoutGuide = .init()
//    
//    private var allowsReceiveUpdating: Bool = true
//    private var allowsReceiveObservering: Bool = true
//    private var allowsAutomaticallyLinking: Bool = false
//    
//    private weak var embeddedViewController: UIViewController?
//    
//    // Gets the absolute content size.
//    private var absoluteContentWidth: CGFloat { return cachedContentSize.height - cachedContentInsets.left - cachedContentInsets.right }
//    private var absoluteContentHeight: CGFloat { return cachedContentSize.height - cachedContentInsets.top - cachedContentInsets.bottom }
//    
//    // If the cached content property has any changes, will trigger the update again.
//    private var cachedContentSize: CGSize = .zero
//    private var cachedContentOffset: CGPoint = .zero
//    private var cachedContentInsets: UIEdgeInsets = .zero
//    
//    // If the cached placeholder size differs from content size, will trigger the update again.
//    private var cachedPlaceholderSize: CGSize?
//}
//
//
//// MARK: -
//
//
//fileprivate extension NSLayoutConstraint {
//    @inline(__always) func priority(to priority: UILayoutPriority) -> Self {
//        self.priority = priority
//        return self
//    }
//    @inline(__always) func save(to output: inout NSLayoutConstraint?) -> Self {
//        output = self
//        return self
//    }
//}
//
//
//
//class XCSegmentedController: UIViewController {
//    
//    var scrollView: UIScrollView {
//        return cachedScrollView
//    }
//    
//    //    unowned(unsafe) var selectedViewController: UIViewController?
//    
//    var viewControllers: [UIViewController]? {
//        set { return updateViewControllersIfNeeded(newValue) }
//        get { return cachedViewControllers }
//    }
//    
//    
//    var selectedIndex: Int {
//        set { return setSelectedIndex(newValue, animated: false) }
//        get { return visibleSelectedIndex }
//    }
//    
//    func setSelectedIndex(_ newValue: Int, animated: Bool) {
//        visibleSelectedIndex = newValue
//        updateContentOffsetIfNeeded(at: newValue)
//    }
//    
//    deinit {
//        guard isViewLoaded else {
//            return
//        }
//        scrollView.removeObserver(self, forKeyPath: "contentOffset")
//    }
//    
//    open override var automaticallyAdjustsScrollViewInsets: Bool {
//        set { return }
//        get { return false }
//    }
//    
//    open override func loadView() {
//        super.loadView()
//        super.automaticallyAdjustsScrollViewInsets = false
//        
//        view.backgroundColor = .white
//        view.addSubview(scrollView)
//        
//        // Setup scroll view.
//        scrollView.frame = view.bounds
//        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        scrollView.isPagingEnabled = true
//        scrollView.showsHorizontalScrollIndicator = false
//        scrollView.showsVerticalScrollIndicator = false
//        scrollView.scrollsToTop = false
//        scrollView.addObserver(self,
//                               forKeyPath: "contentOffset",
//                               options: .new,
//                               context: .init(mutating: sel_getName(#selector(updateContentOffsetWithObserver(_:)))))
//        
//        // In the iPhone X landscape mode, this is the wrong behavior.
//        if #available(iOS 11.0, *) {
//            scrollView.contentInsetAdjustmentBehavior = .never
//        }
//    }
//    
//    open override func viewWillLayoutSubviews() {
//        super.viewWillLayoutSubviews()
//        
//        // Generates the current visible bounds.
//        var bounds = CGRect(x: 0,
//                            y: -scrollView.contentInset.top,
//                            width: scrollView.frame.width,
//                            height: scrollView.frame.height)
//        
//        // In iOS 11, must use `adjustedContentInset`
//        if #available(iOS 11.0, *) {
//            bounds.origin.y = -scrollView.adjustedContentInset.top
//        }
//        
//        // If the bounds is not change, ignore.
//        guard bounds != visibleBounds else {
//            return
//        }
//        
//        // Update content size for count and width.
//        updateContentSizeIfNeeded(bounds)
//        
//        // Update subviews layout on bounds is changed.
//        updateViewControllerSubviewsIfNeeded(bounds)
//        
//        // Restore content offset on bounds is changed.
//        updateContentOffsetIfNeeded(at: selectedIndex)
//        
//        // Record the current visible rect for reduce the calculation.
//        visibleBounds = bounds
//    }
//    
//    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
//        // Automatically perform to the specified method for context.
//        context.map {
//            _ = perform(sel_registerName($0.assumingMemoryBound(to: Int8.self)), with: object, with: change)
//        }
//    }
//    
//    
//    
//    // MARK: -
//    
//    
//    @nonobjc fileprivate func updateContentSizeIfNeeded(_ newValue: CGRect) {
//        // Calculate the current content size.
//        let newContentSize = CGSize(width: newValue.width * .init(viewControllers?.count ?? 0),
//                                    height: 0)
//        
//        // If the current content size is not change, ignore this call.
//        guard newContentSize != scrollView.contentSize else {
//            return
//        }
//        
//        // Update content size and resotre content offset.
//        scrollView.contentSize = newContentSize
//    }
//    
//    @nonobjc fileprivate func updateContentOffsetIfNeeded(_ contentOffset: CGPoint) {
//        // If the view controller is not set, ignore this call.
//        guard  let count = viewControllers?.count, count != 0 else {
//            return
//        }
//        
//        // Computes the currently visible controller.
//        let newValue = min(Int(trunc(contentOffset.x / view.frame.width)), count - 1) ... min(Int(ceil(contentOffset.x / view.frame.width)), count - 1)
//        
//        // If the range is not change, ignore this call.
//        guard visibleRange != newValue else {
//            return
//        }
//        
//        // Remove the invisible controller.
//        visibleRange?.filter { !newValue.contains($0) }.forEach {
//            // If the controller view is not loaded, ignore the call.
//            viewControllers?[$0].viewIfLoaded?.removeFromSuperview()
//            viewControllers?[$0].removeFromParent()
//        }
//        
//        // Add visable view contorller.
//        newValue.filter { !(visibleRange?.contains($0) ?? false) }.forEach {
//            // If the controller doesn't load the view yet, force load it.
//            (viewControllers?[$0]).map {
//                addChild($0)
//                scrollView.addSubview($0.view)
//            }
//        }
//        
//        // Update current selected index for user operator.
//        if allowsAutomaticallyLinking {
//            visibleSelectedIndex = newValue.lowerBound
//        }
//        
//        // Update current visable indexs.
//        visibleRange = newValue
//    }
//    
//    @nonobjc fileprivate func updateContentOffsetIfNeeded(at index: Int) {
//        // If the view controller is not set, ignore this call.
//        guard  let count = viewControllers?.count, count != 0 else {
//            return
//        }
//        
//        // Update content offset for selected index.
//        scrollView.setContentOffset(.init(x: scrollView.frame.width * .init(index),
//                                          y: scrollView.contentOffset.y), animated: false)
//    }
//    
//    @objc fileprivate func updateContentOffsetWithObserver(_ scrollView: UIScrollView) {
//        // Checks whether the current state allows for scroll events to be update.
//        guard allowsReceiveObservering else {
//            return
//        }
//        
//        let edg: UIEdgeInsets
//        let offset: CGPoint = scrollView.contentOffset
//        
//        // In iOS11, must use `adjustedContentInset`
//        if #available(iOS 11.0, *) {
//            edg = scrollView.adjustedContentInset
//        } else {
//            edg = scrollView.contentInset
//        }
//        
//        // Only in the manual operation only requires synchronization
//        allowsAutomaticallyLinking = scrollView.isDragging || scrollView.isDecelerating
//        
//        // Automatic update content offset.
//        updateContentOffsetIfNeeded(.init(x: offset.x + edg.left, y: offset.y + edg.top))
//        
//        // When the update is finished, it is forbidden.
//        allowsAutomaticallyLinking = false
//    }
//    
//    @nonobjc fileprivate func updateViewControllersIfNeeded(_ newValue: [UIViewController]?) {
//        
//        // Remove all expired view contorller.
//        cachedViewControllers?.filter { newValue?.contains($0) ?? false }.forEach {
//            $0.viewIfLoaded?.removeFromSuperview()
//            $0.removeFromParent()
//        }
//        
//        // Update cache for new view controllers.
//        cachedViewControllers = newValue
//        
//        // If the view has been loaded, recalculate the content size.
//        viewIfLoaded?.setNeedsLayout()
//        visibleBounds = nil
//    }
//    
//    @nonobjc fileprivate func updateViewControllerSubviewsIfNeeded(_ newValue: CGRect) {
//        // Update frame for all subviews.
//        viewControllers?.enumerated().forEach {
//            $1.view.frame = CGRect(x: newValue.minX + newValue.width * .init($0),
//                                   y: newValue.minY,
//                                   width: newValue.width,
//                                   height: newValue.height)
//        }
//    }
//    
//    //    @nonobjc fileprivate func updateNavigationControllerContentInsetIfNeeded(_ viewController: UIViewController) {
//    //
//    //        // In before iOS 11 `self.topLayoutGuidle` and `self.bottomLayoutGuide` will not be updated automatically.
//    //        if #available(iOS 11.0, *) {
//    //            return
//    //        }
//    //
//    //        var edg1 = _contentOverlayInsets()
//    //        var edg2 = edg1
//    //
//    ////        edg2.left = 0
//    ////        edg2.right = 0
//    //
//    ////        viewController._setContentOverlayInsets(edg1)
//    ////        viewController._setNavigationControllerContentInsetAdjustment(edg2)
//    //    }
//    
//    // MARK: -
//    
//    private var allowsReceiveUpdating: Bool = true
//    private var allowsReceiveObservering: Bool = true
//    private var allowsAutomaticallyLinking: Bool = false
//    
//    private var visibleBounds: CGRect?
//    private var visibleRange: ClosedRange<Int>?
//    private var visibleSelectedIndex: Int = 0
//    
//    private var cachedScrollView: UIScrollView = .init()
//    private var cachedViewControllers: [UIViewController]?
//}
//
//
//// MARK: -
//
//
//fileprivate extension UIViewController {
//    
//    /// Update the view controller content overlay inset.
//    @NSManaged func _setContentOverlayInsets(_ arg1: UIEdgeInsets)
//    @NSManaged func _contentOverlayInsets() -> UIEdgeInsets
//    
//    @NSManaged func _setNavigationControllerContentInsetAdjustment(_ arg1: UIEdgeInsets)
//    @NSManaged func _setNavigationControllerContentOffsetAdjustment(_ arg1: CGFloat)
//}
//
//fileprivate extension XCSegmentedController {
//    
//    override func _setContentOverlayInsets(_ arg1: UIEdgeInsets) {
//        super._setContentOverlayInsets(arg1)
//        
//        // In before iOS 11 `self.topLayoutGuidle` and `self.bottomLayoutGuide` will not be updated automatically.
//        if #available(iOS 11.0, *) {
//            return
//        }
//        
//        // NOTE: This is safe code because it will only be executed before iOS 11.
//        viewControllers?.forEach {
//            $0._setContentOverlayInsets(arg1)
//        }
//    }
//    
//    override func _setNavigationControllerContentInsetAdjustment(_ arg1: UIEdgeInsets) {
//        super._setNavigationControllerContentInsetAdjustment(arg1)
//        
//        // In before iOS 11 `self.topLayoutGuidle` and `self.bottomLayoutGuide` will not be updated automatically.
//        if #available(iOS 11.0, *) {
//            return
//        }
//        
//        // Get navigation inset from content overlay inset.
//        var edg = _contentOverlayInsets()
//        
//        edg.left -= viewIfLoaded?.layoutMargins.left ?? 0
//        edg.right -= viewIfLoaded?.layoutMargins.left ?? 0
//        
//        // NOTE: This is safe code because it will only be executed before iOS 11.
//        viewControllers?.filter({ $0.isViewLoaded && $0.automaticallyAdjustsScrollViewInsets }).forEach {
//            $0._setNavigationControllerContentInsetAdjustment(edg)
//        }
//    }
//}



//struct VelocityFilter {
//
//    var velocity: Double {
//
//        var result = 0.0
//        if sample.dt >= 0.001 {
//            result = (sample.end - sample.start) / sample.dt
//        }
//        if previousSample.dt > 0 {
//            var result2 = 0.0
//            if previousSample.dt >= 0.001 {
//                result2 = (previousSample.end - previousSample.start) / previousSample.dt
//                result2 = result2 * 0.75
//            }
//            result = result * 0.25 + result2
//        }
//        return result
//    }
//
//    mutating func add(_ value: Double, time: CFTimeInterval = CACurrentMediaTime()) {
//        print("\(value) => \(time)")
//
//        let t1 = time - previousTime
//        if t1 > 0.008 {
//
//            previousSample = sample
//            sample = (previousValue, value, t1)
//        }
//
//        previousValue = value
//        previousTime = time
//    }
//
//    mutating func reset(_ value: Double) {
//
//        sample = (0, 0, 0)
//        previousSample = (0, 0, 0)
//
//        previousTime = 0
//        previousValue = value
//
//    }
//
//    var sample: (start: Double, end: Double, dt: Double) = (0, 0, 0)
//    var previousSample: (start: Double, end: Double, dt: Double) = (0, 0, 0)
//
//    var previousValue: Double = 0
//    var previousTime: CFTimeInterval = 0
//}
//
//var heightVelocityFilter: VelocityFilter = .init()
//var heightAccelerationFilter: VelocityFilter = .init()
//
//
//        let parameters = UISpringTimingParameters(mass: 1, stiffness: 471.5, damping: 30.700000762939453, initialVelocity: .init(dx: 0, dy: 7.8403829294827041))
//        let sp = Spring(mass: 1, stiffness: 471.5, damping: 30.700000762939453, initialVelocity: 7.8403829294827041)
//struct Spring {
//
//    init(mass: Double, stiffness: Double, damping: Double, initialVelocity: Double) {
//
//        self.mass = mass
//        self.stiffness = stiffness
//        self.damping = damping
//        self.initialVelocity = initialVelocity
//
//        let k = stiffness // stiffness of the spring (N/m)
//        let m = mass  // mass(kg)
//        let c = damping
//
//        let ωn = sqrt(k / m) // m_exact.omega_n = sqrt(m_exact.k / m_exact.m);
//        let zeta = c / (2 * ωn * m) // m_exact.zeta = m_exact.c / (2 * m_exact.omega_n * m_exact.m);
//        let ωd = ωn * sqrt(1 - zeta * zeta) // m_exact.omega_d = m_exact.omega_n * sqrt(1 - m_exact.zeta * m_exact.zeta);
//
//        print(ωd)
//
//        self.u1 = sqrt(stiffness / mass)
//        self.u2 = damping / (sqrt(stiffness * mass) * 2)
//        self.u3 = self.u1 * sqrt(1 - self.u2 * self.u2)
//
//        self.u4 = 0x3FF0000000000000
//
//        let t2 = self.u1 * self.u2
//
//        let t1 = self.u2 * self.u2
//        if t1 <= 1 {
//            self.u5 = (t2 - initialVelocity) / self.u3
//        } else {
//            self.u5 = self.u1 - initialVelocity
//        }
//
//        self.u6 = self.u2 * (self.u1 * self.u5) + self.u3
//
//        let xmm5 = min(self.u1 * self.u2,
//                       self.u1 * self.u2 * self.u3 * 2 + self.u1 * self.u1 * self.u2 * self.u2 * self.u5)
//
//        let xmm6 = min(self.u3 * self.u5,
//                       self.u3 * self.u5 * self.u3)
//
//
//        self.u7 = xmm5 - xmm6
//
//        let xmm3 = (self.u1 * self.u1) * (self.u2 * self.u2)
//        let xmm1 = self.u5 * 2 * self.u3 * self.u1 * self.u2
//
//        self.u8 = (xmm3 - xmm1) - self.u3 * self.u3
//    }
//
//    var mass: Double
//    var stiffness: Double
//    var damping: Double
//    var initialVelocity: Double
//
//    var u1: Double
//    var u2: Double
//    var u3: Double
//
//    var u4: UInt64
//
//    var u5: Double
//    var u6: Double
//
//    var u7: Double
//    var u8: Double
//
////    double k = 0;
////    double m = 0;
////    double c = 0;
////
////    double omega_n = 0;
////    double omega_d = 0;
////    double zeta = 0;
////
////    double amp = 0;
////    double phi = 0;
////
////    double crit_c1 = 0;
////    double crit_c2 = 0;
////
////    double over_c1 = 0;
////    double over_c2 = 0;
////
////    double exp_power = 0;
//}


//allowsGroupOpacity = YES
//compositingFilter = colorBurnBlendMode
//
//allowsGroupOpacity = YES
//compositingFilter = plusD
