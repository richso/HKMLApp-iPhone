//
//  ViewController.swift
//  HKMLApp
//
//  Created by Richard So on 6/11/2017.
//  Copyright © 2017 Netrogen Creative. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {

    @IBOutlet weak var webView: WKWebView!
    let html_domain = "www.hkml.net"
    let mainUrl = "http://www.hkml.net/Discuz/index.php"
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var forwardButton: UIBarButtonItem!
    @IBOutlet weak var reloadButton: UIBarButtonItem!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let jqCDN = "http://code.jquery.com/jquery-1.12.4.min.js"
        var jquery = try? String(contentsOf: URL(string: jqCDN)!, encoding: String.Encoding.utf8)
        jquery = (jquery!) + " $j=jQuery.noConflict();";
        let jqScript = WKUserScript(source: jquery!, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        
        let config = webView.configuration
        
        config.userContentController.addUserScript(jqScript)
        
        let scriptURL = "https://raw.githubusercontent.com/richso/hkmlApp/master/public_html/hkmlApp.js?" + String(arc4random())
        let scriptContent = try? String(contentsOf: URL(string: scriptURL)!, encoding: String.Encoding.utf8)
        
        let script = WKUserScript(source: scriptContent!, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        
        config.userContentController.addUserScript(script)
        self.webView.navigationDelegate = self
        self.webView.uiDelegate = self
        
        webView.addObserver(self, forKeyPath: "loading", options: .new, context: nil)
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        
        webView.addObserver(self, forKeyPath: "title", options: .new, context: nil)
        
        webView.load(URLRequest(url:URL(string:mainUrl)!))
        
        backButton.isEnabled = false
        forwardButton.isEnabled = false

    }

    @IBAction func back(sender: UIBarButtonItem) {
        webView.goBack()
    }
    
    @IBAction func forward(sender: UIBarButtonItem) {
        webView.goForward()
    }
    
    @IBAction func reload(sender: UIBarButtonItem) {
        let request = URLRequest(url:webView.url!)
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
            
            titleLabel.text = webView.title
            
            let scriptURL = "http://raw.githubusercontent.com/richso/hkmlApp/master/public_html/hkmlApp-end.js?" + String(arc4random())
            let scriptContent = try? String(contentsOf: URL(string: scriptURL)!, encoding: String.Encoding.utf8)
            webView.evaluateJavaScript(scriptContent!)
        }
        if (keyPath == "facebookshare") {
            
            let activityViewController = UIActivityViewController(
                activityItems: ["Share on facebook"],
                applicationActivities:nil)
            
            present(activityViewController, animated: true, completion: nil)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        progressView.setProgress(0.0, animated: false)
        
        //let scriptURL = "http://raw.githubusercontent.com/richso/hkmlApp/master/public_html/hkmlApp-end.js?" + String(arc4random())
        //let scriptContent = try? String(contentsOf: URL(string: scriptURL)!, encoding: String.Encoding.utf8)
        //webView.evaluateJavaScript(scriptContent!)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping ((WKNavigationActionPolicy) -> Void)) {
        
        // open default browser for external link
        if (navigationAction.navigationType == WKNavigationType.linkActivated) {
            if ((navigationAction.request.url?.absoluteString.lowercased().hasPrefix("facebookshare:"))!) {
                let str = navigationAction.request.url?.absoluteString ?? ""
                NSLog(str)
                
                let index = str.index(str.startIndex, offsetBy: 14)
                let shareurl = String(str[index...])
                // todo: still need to remove the facebook sharer URL prefix
                // and convert the "&amp;" to "&"
                // todo: how to make the FB available in the share UI
                
                NSLog(shareurl)
                
                let url = URL(string: shareurl)
                let activityViewController = UIActivityViewController(
                    activityItems: [url ?? ""],
                    applicationActivities: nil)
                
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

