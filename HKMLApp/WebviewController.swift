//
//  ViewController.swift
//  HKMLApp
//
//  Created by Richard So on 6/11/2017.
//  Copyright © 2017 Netrogen Creative. All rights reserved.
//

import UIKit
import WebKit
//import FacebookShare
import SKPhotoBrowser

class WebviewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler
{
    @IBOutlet weak var webView: WKWebView!
    let html_domain = "www.hkml.net"
    let path_prefix = "http://www.hkml.net/Discuz/"
    let mainUrl = "http://www.hkml.net/Discuz/index.php"
    let touchSwipe = "https://raw.githubusercontent.com/mattbryson/TouchSwipe-Jquery-Plugin/master/jquery.touchSwipe.min.js"
    let hkmlAppJs = "https://raw.githubusercontent.com/richso/hkmlApp/master/public_html/hkmlApp.js"
    let jqCDN = "http://code.jquery.com/jquery-1.12.4.min.js"
    var targetUrl = ""
    var wkProcessPool: WKProcessPool?
    
    var parentController: DetailViewController!
    
    @IBOutlet weak var progressView: UIProgressView!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    var detailItem: MasterViewController.Model? {
        didSet {
            // Update the view.
            loadWebview()
        }
    }
    
    func loadWebview() {
        var urlstr = ""
        if ((detailItem) == nil) {
            urlstr = mainUrl
        } else {
            urlstr = (detailItem?.href)!
        }
        
        NSLog("@loadurl: " + urlstr)
        
        targetUrl = urlstr
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSLog("@viewDidLoad")
        
        let config = webView.configuration
        
        config.processPool = self.wkProcessPool!
        config.userContentController.add(self, name: "hkmlAppCookie")
        config.userContentController.add(self, name: "hkmlAppThumbnail")

        let filePath = Bundle.main.path(forResource: "jquery-1.12.4.min", ofType: "js")
        var jquery = try? String(contentsOfFile: filePath!, encoding:String.Encoding.utf8) //try? String(contentsOf: URL(string: jqCDN)!, encoding: String.Encoding.utf8)
        
        jquery = (jquery!) + " $j=jQuery.noConflict();";
        let jqScript = WKUserScript(source: jquery!, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        
        config.userContentController.addUserScript(jqScript)
        
        let swipefilePath = Bundle.main.path(forResource: "jquery.touchSwipe.min", ofType: "js")
        let jsTouchSwipe = try? String(contentsOfFile: swipefilePath!, encoding:String.Encoding.utf8)
        let sTouchSwipe = WKUserScript(source: jsTouchSwipe!, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        
        config.userContentController.addUserScript(sTouchSwipe)
        
        let cfEnc = CFStringEncodings.big5_HKSCS_1999
        let nsEnc = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(cfEnc.rawValue))
        let big5encoding = String.Encoding(rawValue: nsEnc) // String.Encoding
        
        let scriptURL = hkmlAppJs + "?" + String(arc4random())
        var scriptContent = try? String(contentsOf: URL(string: scriptURL)!, encoding: big5encoding)
        if (scriptContent == nil) {
            let scriptPath = Bundle.main.path(forResource: "hkmlApp", ofType: "js")
            scriptContent = try? String(contentsOfFile: scriptPath!, encoding:big5encoding)
        }

        let script = WKUserScript(source: scriptContent!, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        
        config.userContentController.addUserScript(script)
        
        self.webView.navigationDelegate = self
        self.webView.uiDelegate = self
        
        webView.addObserver(self, forKeyPath: "loading", options: .new, context: nil)
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        
        webView.addObserver(self, forKeyPath: "title", options: .new, context: nil)
        
        if (targetUrl == "") {
            targetUrl = mainUrl
        }
        
        NSLog("@didload: " + targetUrl)
        
        let urlRequest = URLRequest(url:URL(string:targetUrl)!)
        
        webView.load(urlRequest)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(self.refreshWebView), for: UIControl.Event.valueChanged)
        webView.scrollView.addSubview(refreshControl)
        
        let leftButton = UIBarButtonItem(title: "返回相集", style: UIBarButtonItem.Style.plain, target: self, action: #selector(goPhotoCollection(_:)))
        
        navigationItem.leftBarButtonItem = leftButton
    }
    
    @objc
    func goPhotoCollection(_ sender: Any) {
        
        //self.performSegue(withIdentifier: "websiteUnwind", sender: sender)
        
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc
    func refreshWebView(sender: UIRefreshControl) {
        webView.reload()
        sender.endRefreshing()
    }
    
    @IBAction func share(sender: UIBarButtonItem) {
        let activityViewController = UIActivityViewController(
            activityItems: [webView.url ?? ""],
            applicationActivities:nil)
        
        present(activityViewController, animated: true, completion: nil)
        
        if (UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad) {
            if (activityViewController.responds(to: #selector(getter: popoverPresentationController))) {
                activityViewController.popoverPresentationController!.barButtonItem = sender;
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (keyPath == "loading") {
            // do nothing
        }
        if (keyPath == "estimatedProgress") {
            progressView.isHidden = webView.estimatedProgress == 1
            progressView.setProgress(Float(webView.estimatedProgress), animated: true)
        }
        if (keyPath == "title") {
            // do nothing
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        progressView.setProgress(0.0, animated: false)
        
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        
        NSLog(error.localizedDescription)
        
        let alert = UIAlertController(title: "Error", message: "Network problem", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping ((WKNavigationActionPolicy) -> Void)) {
        
        // open default browser for external link
        if (navigationAction.navigationType == WKNavigationType.linkActivated) {
            if ((navigationAction.request.url?.absoluteString.lowercased().hasPrefix("facebookshare:"))!) {
                let str = navigationAction.request.url?.absoluteString ?? ""
                
                let index = str.index(str.startIndex, offsetBy: 14)
                let shareurl = String(str[index...]).replacingOccurrences(of:"%23", with: "#")
                
                NSLog("shareUrl: " + shareurl)
                
                let activityViewController = UIActivityViewController(
                    activityItems: [URL(string: shareurl) ?? ""],
                    applicationActivities:nil)
                
                present(activityViewController, animated: true, completion: nil)
                
                if (UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad) {
                    if (activityViewController.responds(to: #selector(getter: popoverPresentationController))) {
                        let visibleRect = self.view.frame.intersection(self.view.superview!.bounds)
                        activityViewController.popoverPresentationController!.sourceView = self.webView
                        activityViewController.popoverPresentationController!.sourceRect = CGRect(x: visibleRect.width / 2, y: visibleRect.origin.y + 20, width: 1, height: 1)
                        
                    }
                }

                decisionHandler(WKNavigationActionPolicy.cancel)
                
            } else if ((navigationAction.request.url?.host!.lowercased().hasSuffix("facebook.com"))!) {
                
                let fbViewController = tabBarController?.viewControllers![1] as? FBViewController
                
                if (fbViewController?.webView == nil) {
                    let urlstr = navigationAction.request.url?.absoluteString
                    let model = MasterViewController.Model(title: "", img: "", href: urlstr!, author: "", author_href: "", masterViewController: nil)
                    fbViewController?.detailItem = model
                } else {
                    fbViewController?.webView.load(URLRequest(url: navigationAction.request.url!))
                }

                tabBarController?.selectedIndex = 1
                decisionHandler(WKNavigationActionPolicy.cancel)

            } else if (!(navigationAction.request.url?.host!.lowercased().hasPrefix(html_domain))!) {
                UIApplication.shared.open(navigationAction.request.url!)
                decisionHandler(WKNavigationActionPolicy.cancel)
            } else {
                decisionHandler(WKNavigationActionPolicy.allow)
            }
            
        } else {
            decisionHandler(WKNavigationActionPolicy.allow)
        }
        
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void) {
        
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            completionHandler()
        }))
        
        present(alertController, animated: true, completion: nil)
    }
    
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (Bool) -> Void) {
        
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            completionHandler(true)
        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            completionHandler(false)
        }))
        
        present(alertController, animated: true, completion: nil)
    }
    
    
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (String?) -> Void) {
        
        let alertController = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
        
        alertController.addTextField { (textField) in
            textField.text = defaultText
        }
        
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            if let text = alertController.textFields?.first?.text {
                completionHandler(text)
            } else {
                completionHandler(defaultText)
            }
        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            completionHandler(nil)
        }))
        
        present(alertController, animated: true, completion: nil)
    }
    
    
    // WKScriptMessageHandler
    
    func userContentController(_ userContentController: WKUserContentController, didReceive: WKScriptMessage) {
        
        if (didReceive.name == "hkmlAppThumbnail") {
            NSLog("@Photo Slide")
            
            //httpCookieFromArray()
            
            if let d = didReceive.body as? [String: Any] {
                let curIdx = d["idx"] as? NSInteger
                let imgurls = d["images"] as? [String]
                
                var images = [SKPhoto]()
                for idx in 0...(imgurls?.count)!-1 {
                    NSLog("@idx: %d, " + imgurls![idx], idx)
                    var imgsrc = imgurls![idx]
                    if (!(imgsrc.hasPrefix("http:") || imgsrc.hasPrefix("https:"))) {
                        imgsrc = path_prefix + imgsrc
                    }
                    let photo = SKPhoto.photoWithImageURL(imgsrc)
                    images.append(photo)
                    photo.shouldCachePhotoURLImage = true
                }
                
                let browser = SKPhotoBrowser(photos: images)
                browser.initializePageIndex(curIdx!)
                present(browser, animated: true, completion: {})
            }
        }
    }
    
    /*
    func httpCookieFromArray() {
        let cookies_tmp = UserDefaults.standard.value(forKey: "cookies")
        
        if (cookies_tmp != nil) {
            let cookies = cookies_tmp as! Dictionary<String, [HTTPCookiePropertyKey : Any]>
            
            for (_, properties) in cookies {
                HTTPCookieStorage.shared.setCookie(HTTPCookie.init(properties: properties)!)
            }
        }
    } */
}

