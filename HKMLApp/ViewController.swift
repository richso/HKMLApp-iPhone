//
//  ViewController.swift
//  HKMLApp
//
//  Created by Richard So on 6/11/2017.
//  Copyright © 2017 Netrogen Creative. All rights reserved.
//

import UIKit
import WebKit
import FacebookShare

class ViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {

    @IBOutlet weak var webView: WKWebView!
    let html_domain = "www.hkml.net"
    let mainUrl = "http://www.hkml.net/Discuz/index.php"
    let touchSwipe = "https://raw.githubusercontent.com/mattbryson/TouchSwipe-Jquery-Plugin/master/jquery.touchSwipe.min.js"
    let hkmlAppJs = "https://raw.githubusercontent.com/richso/hkmlApp/master/public_html/hkmlApp.js"
    let jqCDN = "http://code.jquery.com/jquery-1.12.4.min.js"
    var targetUrl = ""
    
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var forwardButton: UIBarButtonItem!
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
        targetUrl = urlstr
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let config = webView.configuration
        
        var jquery = try? String(contentsOf: URL(string: jqCDN)!, encoding: String.Encoding.utf8)
        jquery = (jquery!) + " $j=jQuery.noConflict();";
        let jqScript = WKUserScript(source: jquery!, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        
        config.userContentController.addUserScript(jqScript)
        
        let jsTouchSwipe = try? String(contentsOf: URL(string: touchSwipe + "?" + String(arc4random()))!, encoding: String.Encoding.utf8)
        let sTouchSwipe = WKUserScript(source: jsTouchSwipe!, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        
        config.userContentController.addUserScript(sTouchSwipe)
        
        let cfEnc = CFStringEncodings.big5_HKSCS_1999
        let nsEnc = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(cfEnc.rawValue))
        let big5encoding = String.Encoding(rawValue: nsEnc) // String.Encoding
        
        let scriptURL = hkmlAppJs + "?" + String(arc4random())
        let scriptContent = try? String(contentsOf: URL(string: scriptURL)!, encoding: big5encoding)
        
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
        
        webView.load(URLRequest(url:URL(string:targetUrl)!))
        
        backButton.isEnabled = false
        forwardButton.isEnabled = false

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(self.refreshWebView), for: UIControlEvents.valueChanged)
        webView.scrollView.addSubview(refreshControl)
    }
    
    @objc func refreshWebView(sender: UIRefreshControl) {
        webView.reload()
        sender.endRefreshing()
    }

    @IBAction func back(sender: UIBarButtonItem) {
        webView.goBack()
    }
    
    @IBAction func forward(sender: UIBarButtonItem) {
        webView.goForward()
    }
    
    @IBAction func share(sender: UIBarButtonItem) {
        let activityViewController = UIActivityViewController(
            activityItems: [webView.url ?? ""],
            applicationActivities:nil)
        
        present(activityViewController, animated: true, completion: nil)
        
    }
    
    @IBAction func home(sender: UIBarButtonItem) {
        let request = URLRequest(url: URL(string:mainUrl)!)
        webView.load(request)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (keyPath == "loading") {
            backButton.isEnabled = webView.canGoBack
            forwardButton.isEnabled = webView.canGoForward
        }
        if (keyPath == "estimatedProgress") {
            progressView.isHidden = webView.estimatedProgress == 1
            progressView.setProgress(Float(webView.estimatedProgress), animated: true)
        }
        if (keyPath == "title") {
            title = webView.title
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
                let shareurl = String(str[index...])
                
                NSLog(shareurl)
                
                /*
                let linkShareCnt = LinkShareContent(url: URL(string:shareurl)!)
                
                try! ShareDialog.show(from: self, content: linkShareCnt)
                */
                let activityViewController = UIActivityViewController(
                    activityItems: [URL(string: shareurl) ?? ""],
                    applicationActivities:nil)
                
                present(activityViewController, animated: true, completion: nil)

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
        
        let alertController = UIAlertController(title: nil, message: prompt, preferredStyle: .actionSheet)
        
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
}

