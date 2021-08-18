//
//  LoginViewController.swift
//  HKMLApp
//
//  Created by Richard So on 01/01/2018.
//  Copyright © 2018 Netrogen Creative. All rights reserved.
//

import UIKit
import WebKit
//import FacebookShare

class LoginViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler
{

    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var progressView: UIProgressView!
    
    let html_domain = "www.hkml.net"
    let hkmlAppJs = "https://raw.githubusercontent.com/richso/hkmlApp/master/public_html/getLoginStatus.js"
    let jqCDN = "http://code.jquery.com/jquery-1.12.4.min.js"
    var loginUrl = "http://www.hkml.net/Discuz/logging.php?action=login"
    
    var sak: SwissArmyKnife?
    
    var callerController: DetailViewController?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSLog("@viewDidLoad")
        
        sak = SwissArmyKnife(loaderParentView: self.view)
        
        let config = webView.configuration
        
        config.userContentController.add(self, name: "hkmlAppCookie")

        let filePath = Bundle.main.path(forResource: "jquery-1.12.4.min", ofType: "js")
        var jquery = try? String(contentsOfFile: filePath!, encoding:String.Encoding.utf8) //try? String(contentsOf: URL(string: jqCDN)!, encoding: String.Encoding.utf8)
        jquery = (jquery!) + " $j=jQuery.noConflict();";
        let jqScript = WKUserScript(source: jquery!, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        
        config.userContentController.addUserScript(jqScript)
        
        let cfEnc = CFStringEncodings.big5_HKSCS_1999
        let nsEnc = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(cfEnc.rawValue))
        let big5encoding = String.Encoding(rawValue: nsEnc) // String.Encoding
        
        let scriptURL = hkmlAppJs + "?" + String(arc4random())
        var scriptContent = try? String(contentsOf: URL(string: scriptURL)!, encoding: big5encoding)
        if (scriptContent == nil) {
            let scriptPath = Bundle.main.path(forResource: "getLoginStatus", ofType: "js")
            scriptContent = try? String(contentsOfFile: scriptPath!, encoding:big5encoding)
        }
        
        let script = WKUserScript(source: scriptContent!, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        
        config.userContentController.addUserScript(script)
        
        self.webView.navigationDelegate = self
        self.webView.uiDelegate = self
        
        webView.addObserver(self, forKeyPath: "loading", options: .new, context: nil)
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        
        webView.addObserver(self, forKeyPath: "title", options: .new, context: nil)
        
        let urlRequest = URLRequest(url:URL(string:loginUrl)!)
        
        webView.load(urlRequest)
        
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (keyPath == "estimatedProgress") {
            progressView.isHidden = webView.estimatedProgress == 1
            progressView.setProgress(Float(webView.estimatedProgress), animated: true)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
            if (!(navigationAction.request.url?.host!.lowercased().hasPrefix(html_domain))!) {
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
    
    
    // WKScriptMessageHandler
    
    func userContentController(_ userContentController: WKUserContentController, didReceive: WKScriptMessage) {
        
        if (didReceive.name == "hkmlAppCookie") {
            sak?.showActivityIndicator()
            
            if let d = didReceive.body as? [[String: String]] {
                var dic = Dictionary<String, [HTTPCookiePropertyKey: Any]>()
                
                NSLog("@cookies before stored to default store")
                
                var dateComponent = DateComponents()
                dateComponent.day = 365
                
                for cookie in d {
                    if (cookie["name"]!.hasPrefix("ppl_")) {
                        NSLog("cookie: " + cookie["name"]!)
                        
                        dic[cookie["name"]!] = [HTTPCookiePropertyKey: Any]()
                        dic[cookie["name"]!]![HTTPCookiePropertyKey.name] = cookie["name"]
                        dic[cookie["name"]!]![HTTPCookiePropertyKey.value] = cookie["value"]
                        dic[cookie["name"]!]![HTTPCookiePropertyKey.path] = "/Discuz/"
                        dic[cookie["name"]!]![HTTPCookiePropertyKey.domain] = "hkml.net"
                        dic[cookie["name"]!]![HTTPCookiePropertyKey.expires] = Calendar.current.date(byAdding: dateComponent, to: Date())
                    }
                }
                UserDefaults.standard.set(dic, forKey:"cookies")
                UserDefaults.standard.synchronize()
                NSLog("@cookies stored to default store")
                
            }
            
            // let some seconds for cookie sync
            sak?.setTimeout(10, block: {
                self.sak?.hideActivityIndicator()
                
                // go back to masterview
                self.navigationController?.popViewController(animated: true)
                
                if (self.callerController != nil) {
                    NSLog("@callerController is not nil")
                    
                    self.callerController?.webView.reload()
                    
                }
                
            })
        }
    }
    
}

