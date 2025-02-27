//
//  NMSegmentedViewController.swift
//  NetEaseMusic
//
//  Created by SAGESSE on 2019/6/11.
//  Copyright © 2019 SAGESSE. All rights reserved.
//

import UIKit

@IBDesignable
open class NMSegmentedControl: XCPagingControl, XCPagingViewDelegate {
    
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    
    @IBInspectable open override var indicatorColor: UIColor? {
        set { return super.indicatorColor = newValue }
        get { return super.indicatorColor }
    }
    
    @IBInspectable open override var shadowImage: UIImage? {
        set { return super.shadowImage = newValue }
        get { return super.shadowImage }
    }
    
    
//    open override func frame(forIndicator page: Int) -> CGRect? {
//        guard page < numberOfPages, let rect = presentedView.layoutAttributesForItem(at: .init(item: page, section: 0))?.frame else {
//            return nil
//        }
//        var nframe = rect
//
//        nframe.origin.x += (rect.width - 12) / 2
//        nframe.origin.y = rect.height - 2
//        nframe.size.width = 12
//        nframe.size.height = 2
//
//        return nframe
//
//    }
    
//    open override func easeIn(_ start: CGFloat, end: CGFloat, value: CGFloat) -> CGFloat {
//        return start * (1 - value) + end * value
//    }
//    open override func easeOut(_ start: CGFloat, end: CGFloat, value: CGFloat) -> CGFloat {
//        return start * (1 - value) + end * value
//    }

    open func pagingView(_ pagingView: XCPagingView, didChangeOffset offset: CGPoint) {
        let newTransition = offset.x / pagingView.bounds.width
        setCurrentPage(forTransition: newTransition, animated: true)
    }

    
    @inline(__always) fileprivate func setup() {
        
        let n0 = #colorLiteral(red: 0.2000285685, green: 0.1999391615, blue: 0.2042790055, alpha: 1)
        let n1 = #colorLiteral(red: 0.5528972149, green: 0.5529660583, blue: 0.5528737307, alpha: 1)
        let h1 = #colorLiteral(red: 0.9977650046, green: 0.2245476842, blue: 0.225217998, alpha: 1)
        
        indicatorColor = h1
        
        setTitleTextAttributes([.foregroundColor: n0, .font: UIFont.boldSystemFont(ofSize: 15)], for: .normal)
        setTitleTextAttributes([.foregroundColor: h1, .font: UIFont.boldSystemFont(ofSize: 15)], for: .selected)
        
        setBadgeTextAttributes([.foregroundColor: n1, .font: UIFont.systemFont(ofSize: 10)], for: .normal)
        setBadgeTextAttributes([.foregroundColor: h1, .font: UIFont.systemFont(ofSize: 10)], for: .selected)
        
        #if TARGET_INTERFACE_BUILDER
        reloadData(titles: ["Page A", "Page B", "Page C"], badgeValues: [1: "999", 2: "New"])
        #endif
    }
}


@objc
open class NMSegmentedViewController: UIViewController, XCPageable, XCParallaxable, XCPagingViewDelegate, XCParallaxingViewDelegate {
    
    
    /// Configure the header view, which will be displays below the status bar / navigation bar.
    @IBOutlet open var headerView: UIView? {
        set { return parallaxing.headerView = newValue }
        get { return parallaxing.headerView }
    }

    /// Configure the content view, which is displays below the header view.
    @IBOutlet open var contentView: UIView? {
        willSet {
            contentView.map {
                contentViews.removeArrangedSubview($0)
                $0.removeFromSuperview()
            }
            newValue.map {
                contentViews.addArrangedSubview($0)
            }
        }
    }
    
    /// Configure the footer view, which is displays below the content view.
    @IBOutlet open var footerView: UIView? {
        willSet {
            // The view controller is not ready, try again later.
            guard isViewLoaded else {
                return
            }

            footerView.map {
                footerViews.removeArrangedSubview($0)
                $0.removeFromSuperview()
                maskView.backgroundColor = .black
            }
            newValue.map {
                maskView.backgroundColor = nil
                footerViews.addArrangedSubview($0)
                footerLayoutGuide.heightAnchor.constraint(equalTo: $0.heightAnchor).isActive = true
            }
        }
    }
    
    /// Configure background view, which will appear under all views.
    @IBOutlet open var backgroundView: UIView? {
        willSet {
            // The view controller is not ready, try again later.
            guard isViewLoaded else {
                return
            }
            
            // First remove the view to clear the constraint.
            backgroundView?.removeFromSuperview()
            
            // Second check the header view needs to be re-added.
            guard let newValue = newValue else {
                return
            }
            
            // Configure the background view.
            newValue.translatesAutoresizingMaskIntoConstraints = false
            parallaxing.insertSubview(newValue, at: 0)
            
            // Restore the all constraints.
            NSLayoutConstraint.activate(
                [
                    newValue.topAnchor.constraint(equalTo: parallaxing.topAnchor),
                    newValue.leftAnchor.constraint(equalTo: parallaxing.leftAnchor),
                    newValue.rightAnchor.constraint(equalTo: parallaxing.rightAnchor),
                    newValue.bottomAnchor.constraint(equalTo: footerLayoutGuide.bottomAnchor),
                ]
            )
        }
    }

    
    /// Configure the prompt view, which displays between the header view and the content view.
    @IBOutlet open var promptView: UIView? {
        get { return cachedPromptView }
        set { return setPromptView(newValue, aniamted: false) }
    }
    
    /// Configure the prompt view with animation if needed.
    open func setPromptView(_ newValue: UIView?, aniamted: Bool) {
        let oldValue = cachedPromptView
        cachedPromptView = newValue
        updateStackView(contentViews, changes: [.newKey: newValue as Any, .oldKey: oldValue as Any], transitionView: parallaxing.presentedView, at: 0, aniamted: aniamted)
    }


    /// Configure the present view, which displays between the footer view and the content view.
    @IBOutlet open var presentView: UIView? {
        get { return cachedPresentView }
        set { return setPresentView(newValue, aniamted: false) }
    }

    /// Configure the present view with animation if needed.
    open func setPresentView(_ newValue: UIView?, aniamted: Bool) {
        let oldValue = cachedPresentView

        // The view controller is not ready, try again later.
        guard isViewLoaded else {
            return
        }
        
        cachedPresentView = newValue
        updateStackView(footerViews, changes: [.newKey: newValue as Any, .oldKey: oldValue as Any], transitionView: footerSuperview, at: 0, aniamted: aniamted)
    }


    /// Configure the segmented control, Note: that he is not responsible for display.
    @IBOutlet open var segmentedControl: NMSegmentedControl? {
        willSet {
            segmentedControl?.removeTarget(self, action: #selector(updateViewController(forSegmentedControl:)), for: .valueChanged)
            newValue?.addTarget(self, action: #selector(updateViewController(forSegmentedControl:)), for: .valueChanged)
        }
    }
    
    
    /// Configure the view controllers.
    @IBOutlet open var viewControllers: [UIViewController]? {
        get { return paging.viewControllers }
        set { return updateViewControllers(newValue) }
    }

    
    /// Configure the paging view eventes forwarders.
    @IBOutlet open var pagingViewDelegates: [UIView & XCPagingViewDelegate]?
    
    /// Configure the parallaxing view eventes forwarders.
    @IBOutlet open var parallaxingViewDelegates: [UIView & XCParallaxingViewDelegate]?
    

    /// Load the necessary components.
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the mask view whitout mask.
        maskView.image = sharedMaskImage
        maskView.backgroundColor = .black

        // Configure the content view & prompt view.
        contentViews.axis = .vertical
        contentViews.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure the footer view & present view.
        footerViews.axis = .vertical
        footerViews.translatesAutoresizingMaskIntoConstraints = false
        footerSuperview.mask = maskView
        footerSuperview.backgroundColor = .white
        footerSuperview.translatesAutoresizingMaskIntoConstraints = false
        footerSuperview.addSubview(footerViews)
        footerSuperview.addLayoutGuide(footerLayoutGuide)
        footerSuperview.addConstraints(
            [
                footerViews.topAnchor.constraint(equalTo: footerSuperview.topAnchor),
                footerViews.leftAnchor.constraint(equalTo: footerSuperview.leftAnchor),
                footerViews.rightAnchor.constraint(equalTo: footerSuperview.rightAnchor),
                footerViews.bottomAnchor.constraint(equalTo: footerSuperview.bottomAnchor),
            ]
        )
        
        // Configure the horizontal pages managing view.
        paging.isBounces = false
        paging.isScrollEnabled = true
        paging.delegate = self
        
        // Configure the vertical parallax animation managing view.
        parallaxing.isBounces = true
        parallaxing.isScrollEnabled = true
        parallaxing.delegate = self
        parallaxing.contentView = contentViews
        parallaxing.footerView = footerSuperview
        
        NSLayoutConstraint.activate(
            [
                footerLayoutGuide.topAnchor.constraint(greaterThanOrEqualTo: topLayoutGuide.bottomAnchor),
                footerLayoutGuide.topAnchor.constraint(equalTo: footerSuperview.topAnchor).priority(.required - 220),
                footerLayoutGuide.leftAnchor.constraint(equalTo: footerSuperview.leftAnchor),
                footerLayoutGuide.widthAnchor.constraint(equalToConstant: 0),
                footerLayoutGuide.heightAnchor.constraint(equalToConstant: 0).priority(.required - 220),
            ]
        )
        
        // Load the automatically embedded controller if needed.
        viewControllers = cachedViewControllers
        cachedViewControllers = []
        
        // Update some subviews must reload when complete.
        footerView.map { footerView = $0 }
        presentView.map { presentView = $0 }
        backgroundView.map { backgroundView = $0 }
    }
    
    /// The `maskView` must be manually update frame.
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        // Calculate the offset in over the height of the navigation bar.
        var nframe = view.bounds
        nframe.origin.y = presentView.map { _ in -min(parallaxing.contentSize.height - parallaxing.contentOffset.y, 0) } ?? 0
        
        // ignore when frame is not has change.
        if maskView.frame != nframe {
            maskView.frame = nframe
        }
    }
    
    /// Inject dependencies that are automatically embbed.
    open override func awakeFromNib() {
        super.awakeFromNib()
        
        // WRANING: Dependency some undocumented api, it work in iOS 9 - iOS 13.
        (value(forKey: "storyboardSegueTemplates") as? Array<AnyObject>)?.forEach {
            // Only check with custom segue.
            guard let name = $0.value(forKeyPath: "segueClassName") as? String, NSClassFromString(name) is NMEmabbedViewControllerSegue.Type else {
                return
            }
            // Mark this template for auto-perform.
            $0.setValue(true, forKey: "performOnViewLoad")
        }
    }
    
    /// Automatically perform to the specified method for context.
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        context.map {
            _ = perform(sel_registerName($0.assumingMemoryBound(to: Int8.self)), with: object, with: change)
        }
    }

    
    open func pagingView(_ pagingView: XCPagingView, viewDidLoad page: Int) {
        (pagingView.viewControllers?[page]).map { (viewController) -> () in
            
            // The `UICollectoinViewController` is specialed.
            if let viewController = viewController as? UICollectionViewController {
                return parallaxing.embed(viewController.collectionView)
            }
            
            // The `UITableViewController` is specialed.
            if let viewController = viewController as? UITableViewController {
                return parallaxing.embed(viewController.tableView)
            }
            
            // Preference for user-provided `scrollView` API.
            if viewController.responds(to: Selector(String("scrollView"))) {
                if let scrollView = viewController.value(forKey: "scrollView") as? UIScrollView {
                    return parallaxing.embed(scrollView)
                }
            }

            if let scrollView = viewController.view as? UIScrollView {
                return parallaxing.embed(scrollView)
            }
        }
    }
    open func pagingView(_ pagingView: XCPagingView, didChangeOffset offset: CGPoint) {
        pagingViewDelegates?.forEach {
            $0.pagingView?(pagingView, didChangeOffset: offset)
        }
    }

    
    open func parallaxingView(_ parallaxingView: XCParallaxingView, didChangeSize size: CGSize) {
        parallaxingViewDelegates?.forEach {
            $0.parallaxingView?(parallaxingView, didChangeSize: size)
        }
    }
    open func parallaxingView(_ parallaxingView: XCParallaxingView, didChangeOffset offset: CGPoint) {
        parallaxingViewDelegates?.forEach {
            $0.parallaxingView?(parallaxingView, didChangeOffset: offset)
        }
    }
    open func parallaxingView(_ parallaxingView: XCParallaxingView, WillChangeOffset offset: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        // Out of range after need to handle.
        guard let presentView = presentView, targetContentOffset.move().y < offset.y else {
            return
        }
        var newOffset = targetContentOffset.move()
        newOffset.y = min(offset.y, newOffset.y + presentView.frame.height)
        targetContentOffset.assign(from: &newOffset, count: 1)
    }
    
    
    /// Apply the title changes on KVO notification.
    @objc fileprivate func updateTitle(forKVO_ viewController: UIViewController) {
        segmentedControl.map {
            if let page = viewControllers?.firstIndex(of: viewController)  {
                $0.setTitle(viewController.tabBarItem?.title ?? viewController.navigationItem.title ?? "Page \(page)", forPage: page)
            }
        }
    }
    
    /// Apply the badge value changes on KVO notification.
    @objc fileprivate func updateBadgeValue(forKVO_ viewController: UIViewController) {
        segmentedControl.map {
            if let page = viewControllers?.firstIndex(of: viewController)  {
                $0.setBadgeValue(viewController.tabBarItem?.badgeValue, forPage: page)
            }
        }
    }
    
    
    /// Apply the view controller on `valueChange` event.
    @objc fileprivate func updateViewController(forSegmentedControl segmentedControl: NMSegmentedControl) {
        paging.setCurrentPage(segmentedControl.currentPage,
                              animated: false)
    }
    
    /// Apply the view controllers changes.
    @objc fileprivate func updateViewControllers(_ newViewControllers: [UIViewController]?) {
        
        // Remove invalid view controller titles and badges listen.
        viewControllers?.filter { !(newViewControllers?.contains($0) ?? false) } .forEach {
            $0.removeObserver(self, forKeyPath: "tabBarItem.title")
            $0.removeObserver(self, forKeyPath: "tabBarItem.badgeValue")
            $0.removeObserver(self, forKeyPath: "navigationItem.title")
        }
        
        // Setup the embedded view controller titles and badges.
        if let control = segmentedControl {
            
            var titles = [String]()
            var badgeValues = [Int: String]()
            
            // Read the title badge from the controller.
            newViewControllers?.enumerated().forEach {
                
                let title = $1.tabBarItem?.title ?? $1.navigationItem.title ?? "Page \($0)"
                let badgeValue = $1.tabBarItem?.badgeValue
                
                titles.append(title)
                badgeValues[$0] = badgeValue
            }
            
            control.reloadData(titles: titles, badgeValues: badgeValues)
        }

        // Listen new view controller titles and badges changes.
        newViewControllers?.filter { !(viewControllers?.contains($0) ?? false) } .forEach {
            $0.addObserver(self, forKeyPath: "tabBarItem.title", options: .new, context: .init(mutating: sel_getName(#selector(updateTitle))))
            $0.addObserver(self, forKeyPath: "tabBarItem.badgeValue", options: .new, context: .init(mutating: sel_getName(#selector(updateBadgeValue))))
            $0.addObserver(self, forKeyPath: "navigationItem.title", options: .new, context: .init(mutating: sel_getName(#selector(updateTitle))))
        }
        
        // Setup view cotnrollers.
        paging.viewControllers = newViewControllers
    }
    
    
    /// Apply the stack view with animation.
    fileprivate func updateStackView(_ stackView: UIStackView, changes: [NSKeyValueChangeKey : Any]?, transitionView: UIView, at index: Int, aniamted: Bool) {
        
        // Need to provide animation?
        guard aniamted else {
            // No aniamtion.
            (changes?[.oldKey] as? UIView).map {
                stackView.removeArrangedSubview($0)
                $0.removeFromSuperview()
            }
            (changes?[.newKey] as? UIView).map {
                stackView.insertArrangedSubview($0, at: index)
            }
            return
        }
        
        // Generate remove animation if needed.
        if let oldValue = changes?[.oldKey] as? UIView {
            
            // The UIStackView can't make to animate after the removed view,
            // so must add view to containerView.
            let rect = transitionView.convert(oldValue.bounds, from: oldValue)
            stackView.removeArrangedSubview(oldValue)
            transitionView.addSubview(oldValue)

            // If there is a constraint in the presentView, it will not be possible to
            // get the frame correctly, so the all constraint must be adde before get the frame.
            oldValue.translatesAutoresizingMaskIntoConstraints = false
            transitionView.addConstraints(
                [
                    oldValue.topAnchor.constraint(equalTo: transitionView.topAnchor),
                    oldValue.leftAnchor.constraint(equalTo: transitionView.leftAnchor),
                    oldValue.rightAnchor.constraint(equalTo: transitionView.rightAnchor),
                ]
            )

            UIView.animate(withDuration: 0.25, animations: { [view] in

                // Update all subviews layout.
                view?.layoutIfNeeded()
                
                // Revert to original position whitout animation.
                UIView.performWithoutAnimation {
                    oldValue.transform = .init(translationX: 0, y: rect.minY)
                }
                
                // Move up the animation.
                oldValue.transform = oldValue.transform.translatedBy(x: 0, y: -rect.height)

            }, completion: { _ in

                oldValue.removeFromSuperview()
                oldValue.transform = .identity
            })
        }
        
        // Generate add animation if needed.
        if let newValue = changes?[.newKey] as? UIView {
            
            // Same as remove animation.
            newValue.translatesAutoresizingMaskIntoConstraints = false
            transitionView.addSubview(newValue)
            transitionView.addConstraints(
                [
                    newValue.topAnchor.constraint(equalTo: transitionView.topAnchor),
                    newValue.leftAnchor.constraint(equalTo: transitionView.leftAnchor),
                    newValue.rightAnchor.constraint(equalTo: transitionView.rightAnchor),
                ]
            )
            transitionView.layoutIfNeeded()
            
            // Need to get the promptView the frame before add view to `UIStackView`.
            newValue.removeFromSuperview()
            stackView.insertArrangedSubview(newValue, at: index)
            newValue.transform = .init(translationX: 0, y: -newValue.frame.height)
            
            UIView.animate(withDuration: 0.25) { [view] in
                
                view?.layoutIfNeeded()
                newValue.transform = .identity
            }
        }
    }
    
    fileprivate var cachedRadius: CGFloat = 10
    fileprivate var cachedMaskBounds: CGRect = .zero
    fileprivate var cachedViewControllers: [UIViewController] = []

    fileprivate var cachedPromptView: UIView?
    fileprivate var cachedPresentView: UIView?
    
    fileprivate lazy var maskView: UIImageView = .init()
    fileprivate lazy var contentViews: UIStackView = .init()
    
    fileprivate lazy var footerViews: UIStackView = .init()
    fileprivate lazy var footerSuperview: UIView = .init()
    fileprivate lazy var footerLayoutGuide: UILayoutGuide = .init()
    
    
    // Shared masked image.
    fileprivate var sharedMaskImage: UIImage? {
        
        // With the radius cache.
        if NMSegmentedViewController.sharedMaskImage?.0 == cachedRadius {
            return NMSegmentedViewController.sharedMaskImage?.1
        }
        
        let bounds = CGRect(x: 0, y: 0, width: cachedRadius * 4, height: cachedRadius * 4)
        
        // Create a mask image.
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)
        UIGraphicsGetCurrentContext()?.clear(bounds)
        UIBezierPath(roundedRect: bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: .init(width: cachedRadius, height: cachedRadius)).fill()
        
        // Get the drawed image & clean context.
        let image = UIGraphicsGetImageFromCurrentImageContext()?.resizableImage(withCapInsets: .init(top: cachedRadius, left: cachedRadius, bottom: cachedRadius, right: cachedRadius))
        UIGraphicsEndImageContext()
        NMSegmentedViewController.sharedMaskImage = (cachedRadius, image)
        return image
        
    }

    // Shared masked image to reduce generation times.
    fileprivate static var sharedMaskImage: (CGFloat, UIImage?)?
}


@objc
open class NMEmabbedViewControllerSegue: UIStoryboardSegue {
    
    open override func perform() {
        // Add view controller to the source view controller.
        (source as? NMSegmentedViewController).map {
            $0.cachedViewControllers.append(destination)
        }
    }
    
}

/// Quickly set up.
fileprivate extension NSLayoutConstraint {
    @inline(__always) func priority(_ priority: UILayoutPriority) -> NSLayoutConstraint {
        self.priority = priority
        return self
    }
}
