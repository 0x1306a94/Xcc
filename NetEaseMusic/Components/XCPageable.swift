//
//  XCPageable.swift
//  XCPageable
//
//  Created by SAGESSE on 2019/6/11.
//  Copyright © 2019 SAGESSE. All rights reserved.
//

import UIKit

public protocol XCPageable: class {
    
    /// Configure the horizontal pages managing view.
    var paging: XCPagingView { get }
    
}

public extension XCPageable where Self: UIView {
    
    /// Configure the horizontal pages managing view.
    var paging: XCPagingView {
        
        // If already created, reuse it.
        if let fsObject = objc_getAssociatedObject(self, &XCPagingView.defaultKey) as? XCPagingView {
            return fsObject
        }
        
        // Create a new implementation object.
        let fsObject = XCPagingView(embed: self)
        objc_setAssociatedObject(self, &XCPagingView.defaultKey, fsObject, .OBJC_ASSOCIATION_RETAIN)
        return fsObject
    }
    
}
public extension XCPageable where Self: UIViewController {
    
    /// Configure the horizontal pages managing view.
    var paging: XCPagingView {
        
        // If already created, reuse it.
        if let fsObject = objc_getAssociatedObject(self, &XCPagingView.defaultKey) as? XCPagingView {
            return fsObject
        }
        
        // Create a new implementation object.
        let fsObject = XCPagingView(embed: self)
        objc_setAssociatedObject(self, &XCPagingView.defaultKey, fsObject, .OBJC_ASSOCIATION_RETAIN)
        return fsObject
    }
    
}


@objc
public protocol XCPagingViewDelegate: class {
    
    
    /// Called after the controller's view is loaded into memory.
    @objc optional func pagingView(_ pagingView: XCPagingView, viewDidLoad page: Int)
    
    /// Notifies the view controller that its view is about to be added to a view hierarchy.
    @objc optional func pagingView(_ pagingView: XCPagingView, viewWillAppear page: Int)
    /// Notifies the view controller that its view was added to a view hierarchy.
    @objc optional func pagingView(_ pagingView: XCPagingView, viewDidAppear page: Int)
    
    /// Notifies the view controller that its view is about to be removed from a view hierarchy.
    @objc optional func pagingView(_ pagingView: XCPagingView, viewWillDisappear page: Int)
    /// Notifies the view controller that its view was removed from a view hierarchy.
    @objc optional func pagingView(_ pagingView: XCPagingView, viewDidDisappear page: Int)
    
    
    @objc optional func pagingView(_ pagingView: XCPagingView, didChangeOffset offset: CGPoint)
    @objc optional func pagingView(_ pagingView: XCPagingView, didChangePage page: Int)

}

@objc
open class XCPagingView: UIView {
    
    
    /// Create a container view with embed view.
    public convenience init(embed view: UIView) {

        self.init()
        self.viewController = nil
        self.updateSuperview(view)
    }
    
    /// Create a container view with embed view controller.
    public convenience init(embed viewController: UIViewController) {

        self.init()
        self.viewController = viewController
        
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

        // Embed to the parent view controller.
        self.viewController?.addChild(self.presentingViewController)
        if self.viewController?.isViewLoaded ?? false {
            self.updateSuperviewWithObserver(viewController)
        }
    }
    
    
    /// Configure the view controllers.
    open var viewControllers: [UIViewController]? {
        willSet {
            guard viewControllers != newValue else {
                return
            }
            updateViewControllersIfNeeded(newValue)
        }
    }
    
    /// Configure the view controllers.
    open func setViewControllers(_ newValue: [UIViewController]?, animated: Bool) {
        viewControllers = newValue
    }
    
    /// Returns the selected view controller of the page.
    open var topViewController: UIViewController? {
        guard currentPage < viewControllers?.count ?? 0 else {
            return nil
        }
        return viewControllers?[currentPage]
    }

    
    /// Configure the presented view.
    open var presentedView: UIScrollView {
        return presentingView
    }
    
    
    /// Configure the selected index.
    open var currentPage: Int {
        set { return setCurrentPage(newValue, animated: false) }
        get { return visiblePage }
    }
    
    /// Configure the selected index.
    open func setCurrentPage(_ newValue: Int, animated: Bool) {
        // Ignore when page is not changes or not view controllers.
        guard visiblePage != newValue, newValue < viewControllers?.count ?? 0 else {
            return
        }
        performWithoutContentChanges {
            updateContentOffsetIfNeeded(at: newValue, animated: animated)
            updateVisibleViewControllerIfNeeded(at: newValue)
        }
    }
    

    /// A Boolean value that controls whether the scroll view bounces past the edge of content and back again.
    open var isBounces: Bool {
        set { return presentingView.bounces = newValue }
        get { return presentingView.bounces }
    }
    
    /// A Boolean value that determines whether scrolling is enabled.
    open var isScrollEnabled: Bool {
        set { return presentingView.isScrollEnabled = newValue }
        get { return presentingView.isScrollEnabled }
    }

    /// Returns the content offset in pages.
    open var contentOffset: CGPoint {
        return presentingView.contentOffset
    }
    /// Returns the content size of pages.
    open var contentSize: CGSize {
        return presentingView.contentSize
    }

    /// Configure the events delegate.
    open weak var delegate: XCPagingViewDelegate?
        
    
    /// Disables all content offset observer.
    open func performWithoutContentChanges(_ actionsWithoutContentChanges: () -> ()) {
        // Because this method is only executed on the main thread, there is no need to lock it.
        let oldValue = isLockedOffsetChanges
        isLockedOffsetChanges = true
        actionsWithoutContentChanges()
        isLockedOffsetChanges = oldValue
    }
    
    /// Automatically perform to the specified method for context.
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        context.map {
            _ = perform(sel_registerName($0.assumingMemoryBound(to: Int8.self)), with: object, with: change)
        }
    }

    /// Configure content size and subviews..
    open override func layoutSubviews() {
        // Update subviews will trigger content offset changes, But the current page no any change.
        performWithoutContentChanges {
            super.layoutSubviews()
            
            // If the bounds is not change, ignore.
            let newVisibleBounds = bounds.offsetBy(dx: 0, dy: presentingView.contentOffset.y)
            guard newVisibleBounds != visibleBounds else {
                return
            }
            
            // Update content size & content offset when self.bounds is change.
            updateContentSizeIfNeeded()
            updateViewControllerSubviewsIfNeeded()
            updateContentOffsetIfNeeded(at: visiblePage, animated: false)
            
            // Record the current visible rect for reduce the calculation.
            visibleBounds = newVisibleBounds
            cachedContentInsets = contentInset(in: presentingView)
        }
    }
    
    
    fileprivate func updateContentSizeIfNeeded() {
        // If the current content size is not change, ignore this call.
        let newContentSize = CGSize(width: bounds.width * .init(viewControllers?.count ?? 0), height: 0)
        guard newContentSize != presentingView.contentSize else {
            return
        }
        presentingView.contentSize = newContentSize
    }
    fileprivate func updateContentOffsetIfNeeded(_ contentOffset: CGPoint) {
        // If the view controller is not set, ignore this call.
        guard let count = viewControllers?.count, count != 0, cachedContentOffset != contentOffset, presentingView.contentSize != .zero else {
            return
        }
        
        // Cache the content offsets to reduce the invalid calls.
        cachedContentOffset = contentOffset

        // Notify delegate of page content offset is update.
        delegate?.pagingView?(self, didChangeOffset: contentOffset)

        // Update visbles view controllers.
        updateVisibleRectIfNeeded(contentOffset)
        updateVisibleViewControllerIfNeeded(at: .init(round(contentOffset.x / frame.width)))
    }
    fileprivate func updateContentOffsetIfNeeded(at index: Int, animated: Bool) {

        guard let count = viewControllers?.count, count != 0 else {
            return
        }
        
        let offset = CGPoint(x: presentingView.frame.width * .init(index), y: presentingView.contentOffset.y)
        
        // Update content offset for selected index.
        presentingView.setContentOffset(offset, animated: animated)
        
        // If this range is not display, must to force the load.
        guard !(visibleRange?.contains(index) ?? false) else {
            return
        }
        
        // Force load view controller.
        updateContentOffsetIfNeeded(offset)
    }
    
    @objc fileprivate func updateContentOffsetWithObserver(_ scrollView: UIScrollView) {
        // Checks whether the current state allows for scroll events to be update.
        guard !isLockedOffsetChanges else {
            return
        }

        let edg = contentInset(in: scrollView)
        let offset = scrollView.contentOffset
        
        // When `contentInsets` has been changes, this means that `contentOffset` for `presentingView`
        // has expired and needs to be re-computed.
        if cachedContentInsets != edg {
            cachedContentInsets = edg
            setNeedsLayout()
        }

        // Only in the manual operation only requires synchronization
        isAutomaticallyLinking = true
        
        // Automatic update content offset.
        updateContentOffsetIfNeeded(.init(x: offset.x + edg.left, y: offset.y + edg.top))

        // When the update is finished, it is forbidden.
        isAutomaticallyLinking = false
    }
    @objc fileprivate func updateContentOverlayAdjustmentWithObserver(_ viewController: UIViewController, change: [NSKeyValueChangeKey : Any]?) {
        // Check the newValue validity when content overlay insets is change.
        guard let newValue = change?[.newKey] as? UIEdgeInsets else {
            return
        }

        // Automatically forward to all controllers.
        // This code is safe because it only executes in earlier versions.
        viewControllers?.forEach {
            if $0.isViewLoaded  {
                $0.setValue(newValue, forKey: contentOverlayAdjustmentKey)
            }
        }
        
        // Record the last value, apply changes when lazy view controller is loaded.
        cachedContentOverlayAdjustment = newValue
    }
    @objc fileprivate func updateContentOverlayInsetsWithObserver(_ viewController: UIViewController, change: [NSKeyValueChangeKey : Any]?) {
        // Check the newValue validity when content overlay insets is change.
        guard let newValue = change?[.newKey] as? UIEdgeInsets else {
            return
        }
        
        // Automatically forward to all controllers.
        // This code is safe because it only executes in earlier versions.
        viewControllers?.forEach {
            if $0.isViewLoaded  {
                $0.setValue(newValue, forKey: contentOverlayInsetsKey)
            }
        }
        
        // Record the last value, apply changes when lazy view controller is loaded.
        cachedContentOverlayInsets = newValue
    }

    fileprivate func updateVisibleRectIfNeeded(_ offset: CGPoint) {

        guard let count = viewControllers?.count, count != 0 else {
            return
        }
        
        // Computes the currently visible controller.
        let newTransition = offset.x / frame.width
        let newValue = min(Int(trunc(newTransition)), count - 1) ... min(Int(ceil(newTransition)), count - 1)
        
        // If the range is not change, ignore this call.
        guard visibleRange != newValue else {
            return
        }
        
        // Calculate the add or remove of the view controller.
        let addPages = newValue.filter { !(visibleRange?.contains($0) ?? false) }
        let removePages = visibleRange?.filter { !newValue.contains($0) } ?? []
        let currentPages = visibleRange?.filter { !appearing.contains($0) && !disappearing.contains($0) } ?? []
        
        // Remove the invisible controller.
        removePages.forEach { index in
            viewController(at: index).map {
                $0.willMove(toParent: nil)
                $0.viewIfLoaded?.removeFromSuperview()
                $0.removeFromParent()
            }
        }
        
        // Add visable view contorller.
        addPages.forEach { index in
            viewController(at: index).map {
                presentingViewController.addChild($0)
                updateViewController($0, at: index)
                $0.didMove(toParent: presentingViewController)
            }
        }
        
        // Update current visable indexs.
        visibleRange = newValue
        
        // The codes is calculate viewWillAppear/viewWillDisappear/viewDidAppear/viewDidDisappear,
        // maybe remove it can improve the performance?
        #if true
        
        // Pages start disappear.
        for page in currentPages {
            disappearing.append(page)
            delegate?.pagingView?(self, viewWillDisappear: page)
        }
        // Pages start appear
        for page in addPages {
            appearing.append(page)
            delegate?.pagingView?(self, viewWillAppear: page)
        }
        
        // Pages end appear.
        for page in newValue where newValue.count == 1 {
            disappearing.firstIndex(of: page).map {
                disappearing.remove(at: $0) // Cancel.
                delegate?.pagingView?(self, viewWillAppear: page)
                delegate?.pagingView?(self, viewDidAppear: page)
            }
            appearing.firstIndex(of: page).map {
                appearing.remove(at: $0)
                delegate?.pagingView?(self, viewDidAppear: page)
            }
        }
        // Pages end disappear.
        for page in removePages {
            appearing.firstIndex(of: page).map {
                appearing.remove(at: $0) // Cancel.
                delegate?.pagingView?(self, viewWillDisappear: page)
                delegate?.pagingView?(self, viewDidDisappear: page)
            }
            disappearing.firstIndex(of: page).map {
                disappearing.remove(at: $0)
                delegate?.pagingView?(self, viewDidDisappear: page)
            }
        }
        
        #endif
    }
    fileprivate func updateVisibleViewControllerIfNeeded(at newPage: Int) {
        // Ignore when the page is no changes.
        guard newPage != visiblePage else {
            return
        }
        
        // Change to new page (no UI action).
        visiblePage = newPage
        
        // Notify delegate of page number is update.
        delegate?.pagingView?(self, didChangePage: newPage)
    }
    
    fileprivate func updateViewController(_ viewController: UIViewController, at index: Int) {
        // The view controller is first load view ?
        let isFirstLoadView = !viewController.isViewLoaded
        
        // Force the view to load and update the view frame.
        viewController.view.frame = bounds(at: index)
        
        // NOTE: `contentOverlayInsets` must to be update when views after added to the view hierarchy.
        if viewController.view !== presentingView {
            presentingView.addSubview(viewController.view)
        }

        // Ignore when not first load.
        guard isFirstLoadView else {
            return
        }
        
        // Fix topLayoutGuide/bottomLayoutGuide issue in iOS 10.
        compatible {
            // Manually simulate the view controller initialization event.
            // This code is safe because it only executes in earlier versions.
            viewController.setValue(cachedContentOverlayInsets, forKey: contentOverlayInsetsKey)
            viewController.setValue(cachedContentOverlayAdjustment, forKey: contentOverlayAdjustmentKey)
        }
        
        // NOTE: In iOS 10, the callback must after `contentOverlayInsets` has been set.
        delegate?.pagingView?(self, viewDidLoad: index)
    }
    fileprivate func updateViewControllersIfNeeded(_ newValue: [UIViewController]?) {
        
        // Remove all expired view contorller.
        viewControllers?.filter { newValue?.contains($0) ?? false }.forEach {
            // Don't remove view when view controller view is not loaded.
            $0.viewIfLoaded?.removeFromSuperview()
            $0.removeFromParent()
        }
        
        // If the view has been loaded, recalculate the content size.
        setNeedsLayout()
        visibleBounds = nil
    }
    fileprivate func updateViewControllerSubviewsIfNeeded() {
        // Update frame for all loaded subviews.
        viewControllers?.enumerated().forEach {
            $1.viewIfLoaded?.frame = bounds(at: $0)
        }
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
        superview.insertSubview(self, at: 0)
        
        // Finally restore the view controller constraints.
        NSLayoutConstraint.activate(
            [
                topAnchor.constraint(equalTo: superview.topAnchor),
                leftAnchor.constraint(equalTo: superview.leftAnchor),
                widthAnchor.constraint(equalTo: superview.widthAnchor),
                bottomAnchor.constraint(equalTo: superview.bottomAnchor),
            ]
        )
    }
    @objc fileprivate func updateSuperviewWithObserver(_ viewController: UIViewController) {
        
        // Apply superview for view controller.
        updateSuperview(viewController.view)
        presentingViewController.didMove(toParent: viewController)
    }
    
    @inline(__always) fileprivate func compatible(_ actions: () -> ()) {
        // In iOS 11+ system versions not perform actions.
        if #available(iOS 11.0, *) {
            return
        }
        actions()
    }
    
    @inline(__always) fileprivate func contentInset(in scrollView: UIScrollView) -> UIEdgeInsets {
        // In iOS11, must use `adjustedContentInset`
        guard #available(iOS 11.0, *) else {
            return scrollView.contentInset
        }
        return scrollView.adjustedContentInset
    }
    @inline(__always) fileprivate func viewController(at index: Int) -> UIViewController? {
        // Must prevent over-boundary
        if index < viewControllers?.count ?? 0 {
            return viewControllers?[index]
        }
        return nil
    }
    
    @inline(__always) fileprivate func bounds(at index: Int) -> CGRect {
        return CGRect(x: bounds.width * .init(index),
                      y: presentingView.contentOffset.y,
                      width: bounds.width,
                      height: bounds.height)
    }
    
    
    // Common init.
    fileprivate init() {
        
        self.presentingView = UIScrollView()
        self.presentingViewController = UIViewController()
        
        // Build base view.
        super.init(frame: CGRect(x: 0, y: 0, width: 375, height: 240))
        
        // Configure the container view.
        self.isOpaque = true
        self.clipsToBounds = false
        self.backgroundColor = nil
        self.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure the preseting view controler.
        self.presentingViewController.view = self.presentingView
        self.presentingViewController.automaticallyAdjustsScrollViewInsets = true

        // Configure the preseting view.
        self.presentingView.bounds = self.bounds
        self.presentingView.isOpaque = true
        self.presentingView.isPagingEnabled = true
        self.presentingView.isDirectionalLockEnabled = true
        self.presentingView.scrollsToTop = false
        self.presentingView.showsVerticalScrollIndicator = false
        self.presentingView.showsHorizontalScrollIndicator = false
        self.presentingView.clipsToBounds = false
        self.presentingView.backgroundColor = nil
        self.presentingView.translatesAutoresizingMaskIntoConstraints = false
        
        // In the iPhone X landscape mode, this is the wrong behavior.
        if #available(iOS 11.0, *) {
            self.presentingView.contentInsetAdjustmentBehavior = .never
        }

        self.addSubview(self.presentingView)
        self.addConstraints(
            [
                self.presentingView.topAnchor.constraint(equalTo: self.topAnchor),
                self.presentingView.leftAnchor.constraint(equalTo: self.leftAnchor),
                self.presentingView.rightAnchor.constraint(equalTo: self.rightAnchor),
                self.presentingView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            ]
        )
        
        // Add pan event observer.
        self.presentingView.addObserver(self, forKeyPath: "contentOffset", options: .new, context: .init(mutating: sel_getName(#selector(updateContentOffsetWithObserver(_:)))))
        
        // Fix topLayoutGuide/bottomLayoutGuide issue in iOS 10.
        self.compatible {
            // This code is safe because it only executes in earlier versions.
            self.presentingViewController.addObserver(self, forKeyPath: contentOverlayInsetsKey, options: .new, context: .init(mutating: sel_getName(#selector(updateContentOverlayInsetsWithObserver(_:change:)))))
            self.presentingViewController.addObserver(self, forKeyPath: contentOverlayAdjustmentKey, options: .new, context: .init(mutating: sel_getName(#selector(updateContentOverlayAdjustmentWithObserver(_:change:)))))
        }
    }
    
    deinit {
        
        // Remove observer when view controller is set.
        self.viewController?.removeObserver(self, forKeyPath: "view")
        self.viewController = nil
        
        // Fix topLayoutGuide/bottomLayoutGuide issue in iOS 10.
        self.compatible {
            // This code is safe because it only executes in earlier versions.
            self.presentingViewController.removeObserver(self, forKeyPath: contentOverlayInsetsKey)
            self.presentingViewController.removeObserver(self, forKeyPath: contentOverlayAdjustmentKey)
        }
        
        self.presentingViewController.removeFromParent()
        self.presentingView.removeObserver(self, forKeyPath: "contentOffset")
    }
    
    
    @available(*, unavailable, message: "An embeddable object must be provided, Please initialize using init(embed:).")
    override public init(frame: CGRect) {
        fatalError("An embeddable object must be provided, Please initialize using init(embed:).")
    }
    
    @available(*, unavailable, message: "An embeddable object must be provided, Please initialize using init(embed:).")
    required public init?(coder aDecoder: NSCoder) {
        fatalError("An embeddable object must be provided, Please initialize using init(embed:).")
    }

    
    fileprivate var isLockedOffsetChanges: Bool = false
    fileprivate var isAutomaticallyLinking: Bool = false
    
    fileprivate var visibleBounds: CGRect?
    fileprivate var visibleRange: ClosedRange<Int>?
    fileprivate var visiblePage: Int = 0
    
    fileprivate var cachedContentOffset: CGPoint?
    fileprivate var cachedContentInsets: UIEdgeInsets?
    fileprivate var cachedContentOverlayInsets: UIEdgeInsets = .zero
    fileprivate var cachedContentOverlayAdjustment: UIEdgeInsets = .zero
    
    fileprivate let contentOverlayInsetsKey: String = "contentOverlayInsets"
    fileprivate let contentOverlayAdjustmentKey: String = "navigationControllerContentInsetAdjustment"
    
    fileprivate var appearing: [Int] = []
    fileprivate var disappearing: [Int] = []
    
    // The current presenting view.
    fileprivate let presentingView: UIScrollView
    fileprivate let presentingViewController: UIViewController
    
    // The current associated view controller.
    fileprivate unowned(unsafe) var viewController: UIViewController?
    
    // Provide a memory address that is available.
    fileprivate static var defaultKey: String = ""
    
}


@objc
open class XCPagingControl: UIControl, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    /// Initializes and returns a newly allocated view object with the specified frame rectangle.
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    /// Returns an object initialized from data in a given unarchiver.
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    open var presentedView: UICollectionView {
        return presentingView
    }
    
    /// Configure the shadow line.
    open var shadowImage: UIImage? {
        set {
            guard newValue != nil else {
                shadowView.backgroundColor = UIColor.lightGray
                shadowView.image = nil
                return
            }
            shadowView.backgroundColor = nil
            shadowView.image = newValue
        }
        get {
            return shadowView.image
        }
    }

    /// Configure the indicator color.
    open var indicatorColor: UIColor? {
        willSet {
            indicatorView.backgroundColor = newValue
        }
    }
    
    
    /// The property value is an integer specifying the current page shown.
    open var currentPage: Int {
        set { return setCurrentPage(newValue, animated: false) }
        get { return visiblePage }
    }
    
    /// Returns the number of pages the receiver has.
    open var numberOfPages: Int {
        return customizedTitles.count
    }
    
    
    /// Set an integer specifying the current page with animation update.
    open func setCurrentPage(_ newPage: Int, animated: Bool) {
        
        guard newPage != visiblePage, newPage < numberOfPages else {
            return
        }
        visiblePage = newPage
        
        // Set to 0 without animation updates.
        var duration = TimeInterval(0.25)
        if !animated {
            duration = 0
        }
        
        // Generate animation if needed.
        UIView.animate(withDuration: duration) {
            
            self.updateContentView(from: newPage, to: newPage, at: 0)
            self.updateIndicatorView(from: newPage, to: newPage, at: 0)
            self.updateVisibleRectIfNeeded(for: newPage, animated: animated)
        }
    }
    
    open func setCurrentPage(forTransition newTransition: CGFloat, animated: Bool) {
        
        guard !isLockedOffsetChanges, numberOfPages > 0 else {
            return
        }
        
        // Calculates the index in transition.
        let from = min(max(Int(newTransition.rounded(.down)), 0), numberOfPages - 1)
        let to = min(max(Int(newTransition.rounded(.up)), 0), numberOfPages - 1)
        if from == to && from == highlightedPage {
            return
        }
        
        let rounded = Int(newTransition + 0.4)
        let level = CGFloat(Int(newTransition * 100 ) % 100) / 100
        
        // If from has been change, the current page alose change.
        if visiblePage != rounded {
            visiblePage = rounded
            inBounds = false
        }
        
        // Update indicator & cell all changes.
        updateContentView(from: from, to: to, at: level)
        updateIndicatorView(from: from, to: to, at: level)
        
        // If the visible content is not synchronize, must be manually synchronize visible content.
        if !inBounds {
            inBounds = true
            updateVisibleRectIfNeeded(for: visiblePage, animated: animated)
        }
    }
    
    open var contentOffset: CGPoint {
        set { return presentingView.contentOffset = newValue }
        get { return presentingView.contentOffset }
    }
    open var contentSize: CGSize {
        // If it has been calculated, use it directly to improve performance.
        if let oldValue = cachedContentSize {
            return oldValue
        }
        
        // Calculate content size for all pages.
        let newValue = CGSize(width: (0 ..< customizedTitles.count).reduce(CGFloat(0)) { $0 + size(forContents: $1).width }, height: 0)
        cachedContentSize = newValue
        return newValue
    }
    
    open var minimumItemSize: CGSize {
        set {
            // Reset the cache.
            customizedMinimumItemSize = newValue.width < 0 ? nil : newValue
            cachedMinimumItemSize = nil
            cachedContentSize = nil
            
            invalidateLayout = true
            setNeedsLayout()
        }
        get {
            // If it has been calculated, use it directly to improve performance.
            if let oldValue = customizedMinimumItemSize ?? cachedMinimumItemSize {
                return oldValue
            }
            
            // If content size exceed bounds, don't need to calculate.
            let width = contentSize.width
            guard width < bounds.width else {
                return .zero
            }
            
            // Calculate minimum item size for all pages.
            let newValue = CGSize(width: max(max(width, bounds.width) / CGFloat(max(customizedTitles.count, 1)), 80), height: 0)
            cachedMinimumItemSize = newValue
            return newValue
        }
    }

    
    /// Reload the items data.
    open func reloadData(titles: [String]?, badgeValues: [Int: String]? = nil) {
        
        inBounds = false
        setNeedsLayout()
        
        cachedBounds = bounds
        cachedItemSizes = [:]
        cachedTitleSizes = [:]
        cachedBadgeSizes = [:]
        cachedContentSize = nil
        cachedMinimumItemSize = nil
        
        customizedTitles = titles ?? []
        customizedBadges = badgeValues ?? [:]
        
        presentingView.reloadData()
        
        updateContentView(from: visiblePage, to: visiblePage, at: 0)
        updateIndicatorView(from: visiblePage, to: visiblePage, at: 0)
    }

    
    /// Returns the title associated with the specified state.
    open func title(forPage page: Int) -> String? {
        return customizedTitles[page]
    }
    
    /// Sets the title to use for the specified state.
    open func setTitle(_ title: String, forPage page: Int) {
        customizedTitles[page] = title
        invalidateLayout = true
        
        // Reset the associated cache.
        cachedItemSizes[page] = nil
        cachedTitleSizes[page] = nil
        cachedContentSize = nil
        cachedMinimumItemSize = nil
        
        setNeedsLayout()
        updateVisibleCellIfNeeded(at: page)
    }
    
    
    /// Returns the badge value associated with the specified state.
    open func badgeValue(forPage page: Int) -> String? {
        return customizedBadges[page]
    }
    
    /// Sets the badge value to use for the specified state.
    open func setBadgeValue(_ badgeValue: String?, forPage page: Int) {
        customizedBadges[page] = badgeValue
        invalidateLayout = true
        
        // Reset the associated cache.
        cachedItemSizes[page] = nil
        cachedBadgeSizes[page] = nil
        cachedContentSize = nil
        cachedMinimumItemSize = nil
        
        setNeedsLayout()
        updateVisibleCellIfNeeded(at: page)
    }
    
    
    /// A float value specifying the width of the page. If the value is {0.0}, XCPagingControl automatically sizes the page.
    open func width(forPage page: Int) -> CGFloat {
        return customizedWidths[page] ?? 0
    }
    
    /// set to 0.0 width to autosize. default is 0.0
    open func setWidth(_ width: CGFloat, forPage page: Int) {
        customizedWidths[page] = width
        invalidateLayout = true
        
        // Reset the associated cache.
        cachedItemSizes[page] = nil
        cachedContentSize = nil
        cachedMinimumItemSize = nil
        
        setNeedsLayout()
        updateVisibleCellIfNeeded(at: page)
    }
    
    
    /// Returns the text attributes of the title for a given control state.
    open func titleTextAttributes(for state: UIControl.State) -> [NSAttributedString.Key : Any]? {
        return customizedTextAttributes[0][state.rawValue]
    }
    
    /// Sets the text attributes of the title for a given control state.
    open func setTitleTextAttributes(_ attributes: [NSAttributedString.Key : Any]?, for state: UIControl.State) {
        customizedTextAttributes[0][state.rawValue] = attributes
        invalidateLayout = true
        
        // Reset the associated cache.
        cachedItemSizes = [:]
        cachedTitleSizes = [:]
        cachedContentSize = nil
        cachedMinimumItemSize = nil
        
        setNeedsLayout()
        updateVisibleCellsIfNeeded()
    }
    
    
    /// Returns the text attributes of the badge for a given control state.
    open func badgeTextAttributes(for state: UIControl.State) -> [NSAttributedString.Key : Any]? {
        return customizedTextAttributes[0][state.rawValue]
    }
    
    /// Sets the text attributes of the badge for a given control state.
    open func setBadgeTextAttributes(_ attributes: [NSAttributedString.Key : Any]?, for state: UIControl.State) {
        customizedTextAttributes[1][state.rawValue] = attributes
        invalidateLayout = true
        
        // Reset the associated cache.
        cachedItemSizes = [:]
        cachedBadgeSizes = [:]
        cachedContentSize = nil
        cachedMinimumItemSize = nil
        
        setNeedsLayout()
        updateVisibleCellsIfNeeded()
    }
    
    
    
    open func apply(for cell: UICollectionViewCell, at page: Int) {
        
        var state = UIControl.State.normal
        if highlightedPage == page {
            state = .selected
        }
        
        titleLabel(for: cell).map { label in
            label.font = font(for: state, at: 0) ?? font(for: .normal, at: 0)
            label.textColor = textColor(for: state, at: 0) ?? textColor(for: .normal, at: 0)
        }
        badgeLabel(for: cell).map { label in
            label.font = font(for: state, at: 1) ?? font(for: .normal, at: 1)
            label.textColor = textColor(for: state, at: 1) ?? textColor(for: .normal, at: 1)
        }
    }
    
    
    open func transition(_ src: UIFont?, dest: UIFont?, percent: CGFloat) -> UIFont? {
        // Try to avoid calculation.
        if src === dest || src == nil || dest == nil {
            return src ?? dest
        }
        
        let s1 = src?.pointSize ?? 0
        let s2 = dest?.pointSize ?? 0
        if s1 == s2 {
            return dest
        }
        
        return dest?.withSize(s1 * (1 - percent) + s2 * percent)
    }
    open func transition(_ src: UIColor?, dest: UIColor?, percent: CGFloat) -> UIColor? {
        // Try to avoid calculation.
        if src === dest || src == nil || dest == nil {
            return src ?? dest
        }
        let begin = percent
        let end = 1 - begin
        
        let colors = UnsafeMutablePointer<CGFloat>.allocate(capacity: 8)
        
        src?.getRed(colors + 0, green: colors + 2, blue: colors + 4, alpha: colors + 6)
        dest?.getRed(colors + 1, green: colors + 3, blue: colors + 5, alpha: colors + 7)
        
        return UIColor(red: colors[0] * end + colors[1] * begin, green: colors[2] * end + colors[3] * begin, blue: colors[4] * end + colors[5] * begin, alpha: colors[6] * end + colors[7] * begin)
    }
    
    
    open func easeIn(_ start: CGFloat, end: CGFloat, value: CGFloat) -> CGFloat {
        return +(end - start) * value * value + start
    }
    open func easeOut(_ start: CGFloat, end: CGFloat, value: CGFloat) -> CGFloat {
        return -(end - start) * value * (value - 2) + start
    }
    
    
    open func frame(forIndicator page: Int) -> CGRect? {
        // Ignore call when page not found.
        guard page < numberOfPages, let rect = presentingView.layoutAttributesForItem(at: .init(item: page, section: 0))?.frame else {
            return nil
        }
        
        // Get content size.
        let title = size(forTitle: page)
        let badge = size(forBadge: page)
        
        // Calculation of starting point.
        let x = rect.minX + (rect.width - (title.width + badge.width)) / 2
        let y = rect.minY
        
        return CGRect(x: x, y: y, width: title.width, height: 2).inset(by: .init(top: 0, left: -6, bottom: 0, right: -6))
    }
    
    
    open func size(forTitle page: Int) -> CGSize {
        // If it has been calculated, use it directly to improve performance.
        if let oldValue = cachedTitleSizes[page] {
            return oldValue
        }
        
        // Query for font in the normal state.
        var attributes = titleTextAttributes(for: .normal) ?? [:]
        
        // Default fonts need to be set when the user does not provide fonts.
        if attributes[.font] == nil {
            attributes[.font] = font(for: .normal, at: 0)
        }
        
        // Compute title string size.
        let title = customizedTitles[page] as NSString
        var newValue = title.boundingRect(with: .zero, options: .usesLineFragmentOrigin, attributes: attributes, context: nil).size
        newValue.width += 6 // left & right add 1px padding.
        cachedTitleSizes[page] = newValue
        return newValue
    }
    open func size(forBadge page: Int) -> CGSize {
        // If it has been calculated, use it directly to improve performance.
        if let oldValue = cachedBadgeSizes[page] {
            return oldValue
        }
        
        // Query for font in the normal state.
        var attributes = badgeTextAttributes(for: .normal) ?? [:]
        
        // Default fonts need to be set when the user does not provide fonts.
        if attributes[.font] == nil {
            attributes[.font] = font(for: .normal, at: 0)
        }
        
        // Compute badge value size.
        let title = customizedBadges[page] as NSString?
        let newValue = title?.boundingRect(with: .zero, options: .usesLineFragmentOrigin, attributes: attributes, context: nil).size ?? .zero
        cachedBadgeSizes[page] = newValue
        return newValue
    }
    open func size(forContents page: Int) -> CGSize {
        // If the user specifies a page width, use it directly.
        if let customized = customizedWidths[page], customized != 0 {
            return CGSize(width: customized, height: 0)
        }
        
        // If it has been calculated, use it directly to improve performance.
        if let oldValue = cachedItemSizes[page] {
            return oldValue
        }
        
        let title = size(forTitle: page)
        let badge = size(forBadge: page)
        let newValue = CGSize(width: title.width + badge.width + 24, height: title.height)
        cachedItemSizes[page] = newValue
        return newValue
    }
    
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        guard numberOfPages != 0 else {
            return
        }
        
        // Reset position when bounds changes.
        if cachedBounds?.size != bounds.size {
            cachedBounds = bounds
            cachedContentSize = nil
            cachedMinimumItemSize = nil
            invalidateLayout = true
        }
        
        // Reset cells layout when layout invalidate.
        if invalidateLayout {
            invalidateLayout = false
            invalidateIndicatorLayout = true
            presentingViewLayout.invalidateLayout()
        }
        
        // Reset indicator layout when indicator layout invalidate.
        if invalidateIndicatorLayout {
            invalidateIndicatorLayout = false
            updateContentView(from: visiblePage, to: visiblePage, at: 0)
            updateIndicatorView(from: visiblePage, to: visiblePage, at: 0)
            updateVisibleRectIfNeeded(for: visiblePage, animated: false)
        }
    }
    
    
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfPages
    }
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Get a cell for resuable queue.
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Item", for: indexPath)
        
        // Build a label if the cell is first create.
        guard cell.superview !== collectionView else {
            apply(for: cell, at: indexPath.item)
            return cell
        }
        
        cell.contentView.subviews.first?.removeFromSuperview()
        
        let centerView = UIView()
        let titleLabel = UILabel()
        let badgeLabel = UILabel()
        
        centerView.isUserInteractionEnabled = false
        centerView.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.tag = -1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        badgeLabel.tag = -2
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        centerView.addSubview(titleLabel)
        centerView.addSubview(badgeLabel)
        
        cell.contentView.addSubview(centerView)
        cell.contentView.addConstraints(
            [
                centerView.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor),
                centerView.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                
                titleLabel.topAnchor.constraint(equalTo: centerView.topAnchor),
                titleLabel.leftAnchor.constraint(equalTo: centerView.leftAnchor, constant: 3),
                titleLabel.bottomAnchor.constraint(equalTo: centerView.bottomAnchor),
                
                badgeLabel.leftAnchor.constraint(equalTo: titleLabel.rightAnchor, constant: 3),
                badgeLabel.rightAnchor.constraint(equalTo: centerView.rightAnchor),
                badgeLabel.lastBaselineAnchor.constraint(equalTo: titleLabel.lastBaselineAnchor, constant: -1)
            ]
        )
        
        apply(for: cell, at: indexPath.item)
        return cell
    }
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = size(forContents: indexPath.item).width
        return CGSize(width: max(width, minimumItemSize.width), height: bounds.height)
    }
    
    open func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // Set the contents.
        titleLabel(for: cell).map { $0.text = customizedTitles[indexPath.item] }
        badgeLabel(for: cell).map { $0.text = customizedBadges[indexPath.item] }
    }
    open func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    }
    
    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Setup current page with animation.
        isLockedOffsetChanges = true
        setCurrentPage(indexPath.item, animated: true)
        sendActions(for: .valueChanged)
        isLockedOffsetChanges = false
    }
    
    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        inBounds = false
    }
    
    open func updateContentView(from: Int, to: Int, at percent: CGFloat) {
        
        let oldValue = highlightedPage
        let newValue = from
        
        // fonts/textColors: row is state, column is index.
        let fonts = [UIControl.State.normal, UIControl.State.selected].map { state in
            (0 ..< 2).map { font(for: state, at: $0) }
        }
        let textColors = [UIControl.State.normal, UIControl.State.selected].map { state in
            (0 ..< 2).map { textColor(for: state, at: $0) }
        }
        
        // If some is a difference `fromPage` and `toPage`, it means there is transition.
        guard from != to else {
            
            // Restore style for previous highlighted page.
            visibleCell(at: oldValue).map {
                titleLabel(for: $0)?.font = fonts[0][0]
                badgeLabel(for: $0)?.font = fonts[0][1]
                badgeLabel(for: $0)?.textColor = textColors[0][1]
                titleLabel(for: $0)?.textColor = textColors[0][0]
            }
            
            // Setup style for highlighted page.
            visibleCell(at: newValue).map {
                titleLabel(for: $0)?.font = fonts[1][0] ?? fonts[0][0]
                badgeLabel(for: $0)?.font = fonts[1][1] ?? fonts[0][1]
                badgeLabel(for: $0)?.textColor = textColors[1][1] ?? textColors[0][1]
                titleLabel(for: $0)?.textColor = textColors[1][0] ?? textColors[0][0]
            }
            
            // Record the current highlighted page.
            highlightedPage = newValue
            return
        }
        
        // If the highlighted style is set, apply the gradient transition.
        visibleCell(at: from).map {
            titleLabel(for: $0)?.font = transition(fonts[1][0], dest: fonts[0][0], percent: percent)
            badgeLabel(for: $0)?.font = transition(fonts[1][1], dest: fonts[0][1], percent: percent)
            badgeLabel(for: $0)?.textColor = transition(textColors[1][1], dest: textColors[0][1], percent: percent)
            titleLabel(for: $0)?.textColor = transition(textColors[1][0], dest: textColors[0][0], percent: percent)
        }
        visibleCell(at: to).map {
            titleLabel(for: $0)?.font = transition(fonts[0][0], dest: fonts[1][0], percent: percent)
            badgeLabel(for: $0)?.font = transition(fonts[0][1], dest: fonts[1][1], percent: percent)
            badgeLabel(for: $0)?.textColor = transition(textColors[0][1], dest: textColors[1][1], percent: percent)
            titleLabel(for: $0)?.textColor = transition(textColors[0][0], dest: textColors[1][0], percent: percent)
        }
        
    }
    
    open func updateIndicatorView(from: Int, to: Int, at percent: CGFloat)  {
        
        guard let fromRect = frame(forIndicator: from), let toRect = frame(forIndicator: to) else {
            return
        }
        
        let x1 = easeIn(fromRect.minX, end: toRect.minX, value: percent)
        let x2 = easeOut(fromRect.maxX, end: toRect.maxX, value: percent)
        
        indicatorView.frame = .init(x: x1, y: bounds.height - fromRect.height, width: x2 - x1, height: fromRect.height)
    }
    
    open func updateVisibleCellIfNeeded(at index: Int) {
        presentingView.indexPathsForVisibleItems.first(where: { $0.item == index }).map { indexPath in
            presentingView.cellForItem(at: indexPath).map {
                collectionView(presentingView, willDisplay: $0, forItemAt: indexPath)
            }
        }
    }
    open func updateVisibleCellsIfNeeded() {
        presentingView.indexPathsForVisibleItems.forEach { index in
            presentingView.cellForItem(at: index).map {
                apply(for: $0, at: index.item)
            }
        }
    }
    
    open func updateVisibleRectIfNeeded(for page: Int, animated: Bool) {
        inBounds = true
        presentingView.scrollToItem(at: .init(item: page, section: 0), at: .centeredHorizontally, animated: animated)
    }
    
    
    fileprivate func visibleCell(at page: Int) -> UICollectionViewCell? {
        if presentingView.indexPathsForVisibleItems.contains(.init(row: page, section: 0)) {
            return presentingView.cellForItem(at: .init(row: page, section: 0))
        }
        return nil
    }
    
    fileprivate func titleLabel(for cell: UICollectionViewCell) -> UILabel? {
        return cell.viewWithTag(-1) as? UILabel
    }
    fileprivate func badgeLabel(for cell: UICollectionViewCell) -> UILabel? {
        return cell.viewWithTag(-2) as? UILabel
    }
    
    @inline(__always) fileprivate func font(for state: UIControl.State, at index: Int) -> UIFont? {
        let font = customizedTextAttributes[index][state.rawValue]?[.font] as? UIFont
        if state == .normal {
            return font ?? UIFont.systemFont(ofSize: 15)
        }
        return font
    }
    @inline(__always) fileprivate func textColor(for state: UIControl.State, at index: Int) -> UIColor? {
        let color = customizedTextAttributes[index][state.rawValue]?[.foregroundColor] as? UIColor
        if state == .normal {
            return color ?? UIColor.white
        }
        return color
    }
    
    @inline(__always) fileprivate func setup() {
        
        shadowView.frame = CGRect(x: 0, y: bounds.height - 1 / UIScreen.main.scale, width: bounds.width, height: 1 / UIScreen.main.scale)
        shadowView.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        shadowImage = nil
        
        indicatorView.frame.size.height = 2
        indicatorView.isUserInteractionEnabled = false
        
        presentingViewLayout.scrollDirection = .horizontal
        presentingViewLayout.minimumLineSpacing = 0
        presentingViewLayout.minimumInteritemSpacing = 0

        presentingView.frame = bounds
        presentingView.backgroundColor = .clear
        presentingView.scrollsToTop = false
        presentingView.showsHorizontalScrollIndicator = false
        presentingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        presentingView.dataSource = self
        presentingView.delegate = self
        presentingView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Item")
        presentingView.addSubview(indicatorView)
        
        if #available(iOS 11.0, *) {
            presentingView.contentInsetAdjustmentBehavior = .never
        }
        
        addSubview(shadowView)
        addSubview(presentingView)
    }
    
    
    fileprivate var inBounds: Bool = false
    fileprivate var visiblePage: Int = 0
    fileprivate var highlightedPage: Int = 0
    fileprivate var isLockedOffsetChanges: Bool = false
    
    fileprivate var invalidateLayout: Bool = false
    fileprivate var invalidateIndicatorLayout: Bool = true
    
    fileprivate var customizedWidths: [Int: CGFloat] = [:]
    fileprivate var customizedMinimumItemSize: CGSize?
    
    fileprivate var customizedTitles: [String] = []
    fileprivate var customizedTextAttributes: [[UInt: [NSAttributedString.Key : Any]]] = .init(repeating: [:], count: 2)
    fileprivate var customizedBadges: [Int: String] = [:]
    
    fileprivate var cachedBounds: CGRect?
    fileprivate var cachedContentSize: CGSize?
    fileprivate var cachedMinimumItemSize: CGSize?
    
    fileprivate var cachedItemSizes: [Int: CGSize] = [:]
    fileprivate var cachedTitleSizes: [Int: CGSize] = [:]
    fileprivate var cachedBadgeSizes: [Int: CGSize] = [:]
    
    fileprivate lazy var shadowView: UIImageView = .init()
    fileprivate lazy var indicatorView: UIView = .init()
    fileprivate lazy var presentingView: UICollectionView = UICollectionView(frame: bounds, collectionViewLayout: presentingViewLayout)
    fileprivate lazy var presentingViewLayout: UICollectionViewFlowLayout = .init()
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
