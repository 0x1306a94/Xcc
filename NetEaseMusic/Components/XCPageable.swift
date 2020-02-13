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
        if let view = objc_getAssociatedObject(self, &XCPagingView.defaultKey) as? XCPagingView {
            return view
        }
        
        // Create a new implementation object.
        let view = XCPagingView(embed: self)
        objc_setAssociatedObject(self, &XCPagingView.defaultKey, view, .OBJC_ASSOCIATION_RETAIN)
        return view
    }
    
}
public extension XCPageable where Self: UIViewController {
    
    /// Configure the horizontal pages managing view.
    var paging: XCPagingView {
        // If already created, reuse it.
        if let view = objc_getAssociatedObject(self, &XCPagingView.defaultKey) as? XCPagingView {
            return view
        }
        
        // Create a new implementation object.
        let view = XCPagingView(embed: self)
        objc_setAssociatedObject(self, &XCPagingView.defaultKey, view, .OBJC_ASSOCIATION_RETAIN)
        return view
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
    open func performWithoutContentChanges(_ actionsWithoutContentChanges: () -> Void) {
        // Because this method is only executed on the main thread, there is no need to lock it.
        let oldValue = isLockedOffsetChanges
        isLockedOffsetChanges = true
        actionsWithoutContentChanges()
        isLockedOffsetChanges = oldValue
    }
    
    /// Automatically perform to the specified method for context.
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
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
        guard let count = viewControllers?.count, count != 0,
            cachedContentOffset != contentOffset,
            presentingView.contentSize != .zero else {
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
    @objc fileprivate func updateContentOverlayAdjustmentWithObserver(_ viewController: UIViewController, change: [NSKeyValueChangeKey: Any]?) {
        // Check the newValue validity when content overlay insets is change.
        guard let newValue = change?[.newKey] as? UIEdgeInsets else {
            return
        }
        
        // Automatically forward to all controllers.
        // This code is safe because it only executes in earlier versions.
        viewControllers?.forEach {
            if $0.isViewLoaded {
                $0.setValue(newValue, forKey: contentOverlayAdjustmentKey)
            }
        }
        
        // Record the last value, apply changes when lazy view controller is loaded.
        cachedContentOverlayAdjustment = newValue
    }
    @objc fileprivate func updateContentOverlayInsetsWithObserver(_ viewController: UIViewController, change: [NSKeyValueChangeKey: Any]?) {
        // Check the newValue validity when content overlay insets is change.
        guard let newValue = change?[.newKey] as? UIEdgeInsets else {
            return
        }
        
        // Automatically forward to all controllers.
        // This code is safe because it only executes in earlier versions.
        viewControllers?.forEach {
            if $0.isViewLoaded {
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
        
        // NOTE: `contentOverlayInsets` must to be update when views after added to the view hierarchy.
        if presentingView !== viewController.view {
            presentingView.addSubview(viewController.view)
        }
        
        // Force the view to load and update the view frame.
        viewController.view.frame = bounds(at: index)

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
                bottomAnchor.constraint(equalTo: superview.bottomAnchor)
            ]
        )
    }
    @objc fileprivate func updateSuperviewWithObserver(_ viewController: UIViewController) {
        // Apply superview for view controller.
        updateSuperview(viewController.view)
        presentingViewController.didMove(toParent: viewController)
    }
    
    @inline(__always) fileprivate func compatible(_ actions: () -> Void) {
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
                self.presentingView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
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
                    let sel = Selector(String("dealloc"))
                    if let imp = class_getMethodImplementation($0.takeUnretainedValue().superclass, sel) {
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
