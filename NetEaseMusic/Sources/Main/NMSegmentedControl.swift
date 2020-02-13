//
//  NMSegmentedControl.swift
//  NetEaseMusic
//
//  Created by SAGESSE on 2019/10/17.
//  Copyright © 2019 SAGESSE. All rights reserved.
//

import UIKit


@IBDesignable
open class NMSegmentedControl: UIControl, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, XCPagingViewDelegate {
    
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
    @IBInspectable  open var shadowImage: UIImage? {
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
    @IBInspectable  open var indicatorColor: UIColor? {
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
    open func titleTextAttributes(for state: UIControl.State) -> [NSAttributedString.Key: Any]? {
        return customizedTextAttributes[0][state.rawValue]
    }
    
    /// Sets the text attributes of the title for a given control state.
    open func setTitleTextAttributes(_ attributes: [NSAttributedString.Key: Any]?, for state: UIControl.State) {
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
    open func badgeTextAttributes(for state: UIControl.State) -> [NSAttributedString.Key: Any]? {
        return customizedTextAttributes[1][state.rawValue]
    }
    
    /// Sets the text attributes of the badge for a given control state.
    open func setBadgeTextAttributes(_ attributes: [NSAttributedString.Key: Any]?, for state: UIControl.State) {
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
        let contents = size(forContents: page)
        
        // Calculation of starting point.
        let x = rect.minX + customContentInsets.left + (rect.width - contents.width) / 2
        let y = rect.minY + customContentInsets.top
        
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
        newValue.width += customTitleInsets.left + customTitleInsets.right
        newValue.height += customTitleInsets.top + customTitleInsets.bottom
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
        let newValue = CGSize(width: title.width + badge.width + customContentInsets.left + customContentInsets.right,
                              height: max(title.height, badge.height) + customContentInsets.top + customContentInsets.bottom)
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
        
        titleLabel.tag = -1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeLabel.tag = -2
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        centerView.isUserInteractionEnabled = false
        centerView.translatesAutoresizingMaskIntoConstraints = false
        centerView.addSubview(titleLabel)
        centerView.addSubview(badgeLabel)
        
        cell.contentView.addSubview(centerView)
        cell.contentView.addConstraints(
            [
                centerView.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor),
                centerView.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                
                titleLabel.topAnchor.constraint(equalTo: centerView.topAnchor),
                titleLabel.leftAnchor.constraint(equalTo: centerView.leftAnchor, constant: customTitleInsets.left),
                titleLabel.bottomAnchor.constraint(equalTo: centerView.bottomAnchor),
                
                badgeLabel.leftAnchor.constraint(equalTo: titleLabel.rightAnchor, constant: customTitleInsets.right),
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
    
    open func pagingView(_ pagingView: XCPagingView, didChangeOffset offset: CGPoint) {
        let newTransition = offset.x / pagingView.bounds.width
        setCurrentPage(forTransition: newTransition, animated: true)
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
    
    open func updateIndicatorView(from: Int, to: Int, at percent: CGFloat) {
        
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
    
    fileprivate var inBounds: Bool = false
    fileprivate var visiblePage: Int = 0
    fileprivate var highlightedPage: Int = 0
    fileprivate var isLockedOffsetChanges: Bool = false
    
    fileprivate var customContentInsets: UIEdgeInsets = .init(top: 0, left: 12, bottom: 0, right: 12)
    fileprivate var customTitleInsets: UIEdgeInsets = .init(top: 0, left: 3, bottom: 0, right: 3)
    
    fileprivate var invalidateLayout: Bool = false
    fileprivate var invalidateIndicatorLayout: Bool = true
    
    fileprivate var customizedWidths: [Int: CGFloat] = [:]
    fileprivate var customizedMinimumItemSize: CGSize?
    
    fileprivate var customizedTitles: [String] = []
    fileprivate var customizedTextAttributes: [[UInt: [NSAttributedString.Key: Any]]] = .init(repeating: [:], count: 2)
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
