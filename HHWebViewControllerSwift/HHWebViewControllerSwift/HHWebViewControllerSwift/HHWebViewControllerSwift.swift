//
//  HHWebViewControllerSwift.swift
//  HHWebViewController
//
//  Created by Donald Angelillo on 6/26/16.
//  Copyright © 2016 Donald Angelillo. All rights reserved.
//

import UIKit

typealias HHWebViewControllerShareCompletionBlock = (activityType: String, completed: Bool, returnedItems: [AnyObject], activityError: NSError?, sharedURL: NSURL?) -> ()

//typedef void(^HHWebViewControllerShareCompletionBlock)(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError, NSURL *sharedURL);

@objc class HHWebViewControllerSwift: UIViewController, UIWebViewDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    var url: NSURL!
    var webView: UIWebView!
    var toolBar: UIToolbar!
    
    var shouldShowControls: Bool = true {
        didSet {
            self.createOrUpdateControls()
        }
    }
    
    var shouldControlsImmediately: Bool = true
    var shouldHideNavBarOnScroll: Bool = true
    var shouldHideStatusBarOnScroll: Bool = true
    var shouldHideToolBarOnScroll: Bool = true
    
    var showControlsInNavBarOniPad: Bool = true {
        didSet {
            if (showControlsInNavBarOniPad) {
                if UI_USER_INTERFACE_IDIOM() != .Pad {
                    showControlsInNavBarOniPad = false
                }
            }
        }
    }
    
    var shouldPreventChromeHidingOnScrollOnInitialLoad: Bool = false
    var shouldShowActionButton: Bool = true
    var shouldShowReaderButton: Bool = true
    var shouldIgnoreWebViewNavigationStackForBackForwardbuttons: Bool = false
    
    var backButton: UIBarButtonItem? = nil
    var forwardButton: UIBarButtonItem? = nil
    var reloadButton: UIBarButtonItem? = nil
    var stopButton: UIBarButtonItem? = nil
    var actionButton: UIBarButtonItem? = nil
    var readerButton: UIBarButtonItem? = nil
    var flexiblespace: UIBarButtonItem? = nil
    var webViewLoadingItems: Int = 0
    
    var initialContentOffset: Float = 0.0
    var previousContentDelta: Float = 0.0
    var scrollingDown: Bool = false
    
    var hadStatusBarHidden: Bool = false
    var hadNavBarHidden: Bool = false
    var hadToolBarHidden: Bool = false
    var isExitingScreen: Bool = false
    
    var shareCompletionBlock: HHWebViewControllerShareCompletionBlock? = nil
    var customShareMessage: String? = nil
    
    weak var webViewDelegate: UIWebViewDelegate? = nil

    init(url: NSURL) {
        super.init(nibName: nil, bundle: nil)
        
        self.url = url
        self.showControlsInNavBarOniPad = true
        self.shouldShowControls = true
        self.shouldControlsImmediately = true
        self.shouldHideNavBarOnScroll = true
        self.shouldHideStatusBarOnScroll = true
        self.shouldHideToolBarOnScroll = true
        self.shouldPreventChromeHidingOnScrollOnInitialLoad = false
        self.shouldShowActionButton = true
        self.shouldShowReaderButton = true
        self.shouldIgnoreWebViewNavigationStackForBackForwardbuttons = false
        self.hadStatusBarHidden = UIApplication.sharedApplication().statusBarHidden
        self.isExitingScreen = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - View Lifecyle
    override func loadView() {
        self.view = UIView(frame: UIScreen.mainScreen().bounds)
        self.view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        self.view.autoresizesSubviews = true
        self.webView = UIWebView(frame: self.view.frame)
        self.webView.autoresizingMask = self.view.autoresizingMask
        self.webView.delegate = self
        self.webView.scrollView.delegate = self
        self.webView.scalesPageToFit = true
        self.view!.addSubview(self.webView)
        self.createOrUpdateControls()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.loadURL(self.url)
    }
    
    override func viewWillAppear(animated: Bool) {
        guard let navController = self.navigationController else {
            assert(self.navigationController == nil, "HHWebViewController must be contained in a navigation controller.")
            return
        }
        
        super.viewWillAppear(animated)
        
        if (self.isMovingToParentViewController()) {
            self.hadToolBarHidden = navController.toolbarHidden
            self.hadNavBarHidden = navController.navigationBarHidden
            
            if self.shouldControlsImmediately {
                self.showUI()
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        //force the status bar and nav toolbar back to their original states when this viewController is being popped off stack
        if (self.isMovingFromParentViewController()) {
            self.isExitingScreen = true
            //UIApplication.sharedApplication().setStatusBarHidden(hadStatusBarHidden, withAnimation: .Fade)
            
            self.navigationController?.setNavigationBarHidden(hadNavBarHidden, animated: animated)
            self.navigationController?.setToolbarHidden(hadToolBarHidden, animated: animated)
            
            //UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: .Fade)
            self.prefersStatusBarHidden()
            self.setNeedsStatusBarAppearanceUpdate()
            
//            if self.respondsToSelector(#selector(UIViewController.setNeedsStatusBarAppearanceUpdate)) {
//                self.prefersStatusBarHidden()
//                self.performSelector(#selector(UIViewController.setNeedsStatusBarAppearanceUpdate))
//            } else {
//                // iOS 6
//                UIApplication.sharedApplication().setStatusBarHidden(hadStatusBarHidden, withAnimation: .Fade)
//            }
        }
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    //MARK: - Rotation
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .All
    }
    
    override func prefersStatusBarHidden() -> Bool {
        if (self.isExitingScreen) {
            return hadStatusBarHidden
        }
        
        if (self.scrollingDown) {
            return true
        }
        
        return false
    }
    
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return .Fade
    }

    
    
    func createOrUpdateControls() {
        if (self.shouldShowControls) {
            
            if (flexiblespace == nil) {
                flexiblespace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
            }
            
            if (backButton == nil) {
                backButton = UIBarButtonItem(customView: HHDynamicBarButton.backButtonViewWithTarget(self, action: #selector(backButtonHit(_:))))
            }
            
            if (forwardButton == nil) {
                forwardButton = UIBarButtonItem(customView: HHDynamicBarButton.forwardButtonViewWithTarget(self, action: #selector(forwardButtonHit(_:))))
            }
            
            if (reloadButton == nil) {
                reloadButton = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: #selector(reloadHit(_:)))
            }
            
            if (stopButton == nil) {
                stopButton = UIBarButtonItem(barButtonSystemItem: .Stop, target: self, action: #selector(stopHit(_:)))
            }
            
            if (readerButton == nil) {
                readerButton = UIBarButtonItem(customView: HHDynamicBarButton.readerButtonViewWithTarget(self, action: "forwardButtonHit:"))
            }
            
            if (actionButton == nil) {
                actionButton = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "stopHit:")
            }
            
            var items: [UIBarButtonItem] = Array()
            items.append(backButton!)
            items.append(forwardButton!)
            items.append(flexiblespace!)
            
            if (self.webViewLoadingItems > 0) {
                items.append(stopButton!)
            } else {
                items.append(reloadButton!)
            }
            
            if (self.shouldShowReaderButton) {
                items.append(flexiblespace!)
                items.append(readerButton!)
            }
            
            if (self.shouldShowActionButton) {
                items.append(flexiblespace!)
                items.append(actionButton!)
            }
            
            if (UI_USER_INTERFACE_IDIOM() == .Pad) {
                if self.showControlsInNavBarOniPad {
                    self.navigationItem.rightBarButtonItems = items.reverse()
                } else {
                    self.toolbarItems = items
                }
            } else {
                self.toolbarItems = items
            }
            
            if self.shouldIgnoreWebViewNavigationStackForBackForwardbuttons {
                backButton?.enabled = true
                forwardButton?.enabled = true
            } else {
                backButton?.enabled = self.webView.canGoBack
                forwardButton?.enabled = self.webView.canGoForward
            }
        }
    }
    
    func backButtonHit(sender: UIBarButtonItem) {
        if (self.shouldIgnoreWebViewNavigationStackForBackForwardbuttons) {
            self.webView.goBack()
            return
        }
        
        if (self.webView.canGoBack) {
            self.webView.goBack()
        }
    }
    
    func forwardButtonHit(sender: UIBarButtonItem) {
        if (self.shouldIgnoreWebViewNavigationStackForBackForwardbuttons) {
            self.webView.goForward()
            return
        }
        
        if (self.webView.canGoForward) {
            self.webView.goForward()
        }
    }
    
    func reloadHit(sender: UIBarButtonItem) {
        self.webView.reload()
    }
    
    func stopHit(sender: UIBarButtonItem) {
        self.webView.stopLoading()
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }

    func readerButtonHit(sender: UIBarButtonItem) {
        //self.loadURL(NSURL(string: "http://www.readability.com/m?url=\(self.url.absoluteString.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding))")!)
        
        self.loadURL(NSURL(string: "http://www.readability.com/m?url=\(self.url.absoluteString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()))")!)
    }
    
    func showUI() {
        if (self.shouldHideNavBarOnScroll) {
            if let navigationController = self.navigationController {
                if (navigationController.navigationBarHidden) {
                    navigationController.setNavigationBarHidden(false, animated: true)
                }
            }
        }
        
        if (self.shouldHideStatusBarOnScroll) {
            //UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: .Fade)
            self.prefersStatusBarHidden()
            self.setNeedsStatusBarAppearanceUpdate()
        }
        
        if (self.shouldShowControls) {
            if (self.shouldHideToolBarOnScroll) {
                if (!self.showControlsInNavBarOniPad) {
                    self.navigationController?.setToolbarHidden(false, animated: true)
                }
            }
        }
    }
    
    func hideUI() {
        if (self.shouldHideNavBarOnScroll) {
            if let navigationController = self.navigationController {
                if (navigationController.navigationBarHidden) {
                    navigationController.setNavigationBarHidden(true, animated: true)
                }
            }
        }
        
        if (self.shouldHideStatusBarOnScroll) {
            //UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .Fade)
            self.prefersStatusBarHidden()
            self.setNeedsStatusBarAppearanceUpdate()
        }
        
        if (self.shouldShowControls) {
            if (self.shouldHideToolBarOnScroll) {
                if (!self.showControlsInNavBarOniPad) {
                    self.navigationController?.setToolbarHidden(true, animated: true)
                }
            }
        }
    }
    
    func loadURL(url: NSURL) {
        if (!url.isEqual(self.url)) {
            self.url = url
        }
        
        self.webView.loadRequest(NSURLRequest(URL: url))
    }
}






class HHDynamicBarButton: UIButton {
    enum HHWebViewButtonType : Int {
        case HHWebViewButtonTypeBackButton
        case HHWebViewButtonTypeForwardButton
        case HHWebViewButtonTypeReaderButton
    }
    
    var hhWebViewButtonType: HHWebViewButtonType
    
    override var highlighted: Bool {
        didSet {
            super.highlighted = highlighted
            self.setNeedsDisplay()
        }
    }
    
    override var enabled: Bool {
        didSet {
            super.enabled = enabled
            self.setNeedsDisplay()
        }
    }
    
    init(frame: CGRect, direction buttonType: HHWebViewButtonType, target: AnyObject, action: Selector) {
        self.hhWebViewButtonType = buttonType
        
        super.init(frame: frame)
    
        self.backgroundColor = UIColor.clearColor()
        self.addTarget(target, action: action, forControlEvents: .TouchUpInside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    class func backButtonViewWithTarget(target: AnyObject, action: Selector) -> HHDynamicBarButton {
        return HHDynamicBarButton(frame: CGRectMake(0, 0, 30, 30), direction: .HHWebViewButtonTypeBackButton, target: target, action: action)
    }
    
    class func forwardButtonViewWithTarget(target: AnyObject, action: Selector) -> HHDynamicBarButton {
        return HHDynamicBarButton(frame: CGRectMake(0, 0, 30, 30), direction: .HHWebViewButtonTypeForwardButton, target: target, action: action)
    }
    
    class func readerButtonViewWithTarget(target: AnyObject, action: Selector) -> HHDynamicBarButton {
        return HHDynamicBarButton(frame: CGRectMake(0, 0, 30, 30), direction: .HHWebViewButtonTypeReaderButton, target: target, action: action)
    }
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        let context: CGContextRef = UIGraphicsGetCurrentContext()!
        
        CGContextSetLineCap(context, .Square)
        CGContextSetLineJoin(context, .Miter)
        CGContextSetLineWidth(context, 2)
        
        if (self.enabled) {
            if (self.highlighted) {
                CGContextSetStrokeColorWithColor(context, UIColor.lightGrayColor().CGColor)
            } else {
                CGContextSetStrokeColorWithColor(context, self.tintColor.CGColor)
            }
            
            CGContextSetAlpha(context, 1.0)
        } else {
            CGContextSetStrokeColorWithColor(context, UIColor.lightGrayColor().CGColor)
            CGContextSetAlpha(context, 0.5)
        }
        
        var x: CGFloat
        var y: CGFloat
        var radius: CGFloat
        
        switch (self.hhWebViewButtonType) {
            
        case .HHWebViewButtonTypeBackButton:
            x = 9
            y = CGRectGetMidY(self.bounds)
            radius = 9
            CGContextMoveToPoint(context, x + radius, y + radius)
            CGContextAddLineToPoint(context, x, y)
            CGContextAddLineToPoint(context, x + radius, y - radius)
            CGContextStrokePath(context)
            break
            
        case .HHWebViewButtonTypeForwardButton:
            x = 21
            y = CGRectGetMidY(self.bounds)
            radius = 9
            CGContextMoveToPoint(context, x - radius, y - radius)
            CGContextAddLineToPoint(context, x, y)
            CGContextAddLineToPoint(context, x - radius, y + radius)
            CGContextStrokePath(context)
            break
            
        case .HHWebViewButtonTypeReaderButton:
            CGContextSetLineWidth(context, 1.5);
            
            CGContextMoveToPoint(context, 5, 5);
            CGContextAddLineToPoint(context, 25, 5);
            
            CGContextMoveToPoint(context, 5, 12);
            CGContextAddLineToPoint(context, 25, 12);
            
            CGContextMoveToPoint(context, 5, 19);
            CGContextAddLineToPoint(context, 25, 19);
            
            CGContextMoveToPoint(context, 5, 26);
            CGContextAddLineToPoint(context, 15, 26);
            
            CGContextStrokePath(context);
            break
            
        }
        
    }
}
