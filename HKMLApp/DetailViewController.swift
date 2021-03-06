//
//  MasterViewController.swift
//  test_master_detail
//
//  Created by Richard So on 24/11/2017.
//  Copyright © 2017 Netrogen Creative. All rights reserved.
//

import UIKit
import WebKit
import SDWebImage
import SKPhotoBrowser

class DetailViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler, UITableViewDelegate, UITableViewDataSource {
    
    
    struct ImgModel {
        var title: String
        var img: String
        var href: String
        var author: String
        var author_href: String
        var img_height: CGFloat = 0
    }
    
    @IBOutlet weak var tableView: UITableView!
    var refreshControl: UIRefreshControl?
    var detailViewController: WebviewController? = nil
    var objects = [ImgModel]()
    var pageIndex: NSInteger!
    var multiController: MultipageViewController!
    var webView : WKWebView!
    
    let path_prefix = "http://www.hkml.net/Discuz/"
    let mainUrl = "http://www.hkml.net/Discuz/index.php"
    let loginUrl = "http://www.hkml.net/Discuz/logging.php?action=login"
    let searchUrl = "http://www.hkml.net/Discuz/search.php"
    var targetUrl = "http://www.hkml.net/Discuz/index.php"
    let hkmlAppJs = "https://raw.githubusercontent.com/richso/hkmlApp/master/public_html/getModelPhotos.js"
    let jqCDN = "http://code.jquery.com/jquery-1.12.4.min.js"
    
    var userContentController : WKUserContentController!
    
    var sak: SwissArmyKnife?
    
    var detailItem: MasterViewController.Model? {
        didSet {
            // Update the view.
            targetUrl = (detailItem?.href)!
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sak = SwissArmyKnife(loaderParentView: self.view)
        SKCache.sharedCache.imageCache = SDToSKCache()

        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
        
        refreshControl = UIRefreshControl()
        tableView.addSubview(refreshControl!)
        refreshControl?.addTarget(self, action: #selector(refreshTableData(_:)), for: .valueChanged)

        let config = WKWebViewConfiguration()
        userContentController = WKUserContentController()
        config.userContentController = userContentController
        webView = WKWebView(frame: CGRect.zero, configuration: config)
        self.view.addSubview(webView)
        
        userContentController.add(self, name: "hkmlApp")
        
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
            let scriptPath = Bundle.main.path(forResource: "getModelPhotos.js", ofType: "js")
            scriptContent = try? String(contentsOfFile: scriptPath!, encoding:big5encoding)
        }
        
        let script = WKUserScript(source: scriptContent!, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        
        config.userContentController.addUserScript(script)
        
        self.webView.navigationDelegate = self
        self.webView.uiDelegate = self
        
        webView.addObserver(self, forKeyPath: "loading", options: .new, context: nil)
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        
        webView.addObserver(self, forKeyPath: "title", options: .new, context: nil)
        
        sak?.showActivityIndicator()
        
        let cookies_tmp = UserDefaults.standard.value(forKey: "cookies")
        
        if (cookies_tmp != nil) {
            let cookies = cookies_tmp as! Dictionary<String, [HTTPCookiePropertyKey : Any]>
            
            for (key, properties) in cookies {
                let cookie = HTTPCookie(properties: properties)
                
                NSLog("@load key: " + key + " value: " + (properties[HTTPCookiePropertyKey.value] as? String)!)
                
                WKWebsiteDataStore.default().httpCookieStore.setCookie(cookie!, completionHandler: nil)
            }
        }
        
        httpCookieFromArray()
        webView.load(URLRequest(url:URL(string:targetUrl)!))

    }

    @objc private func refreshTableData(_ sender: Any) {
        webView.reload()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        SDImageCache.shared().clearMemory()
    }
    
    @IBAction
    func onClickWebsite(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let tabBarController = storyboard.instantiateViewController(withIdentifier:"tabViewController") as? UITabBarController
        
        let wvViewController = tabBarController?.viewControllers![0] as? WebviewController
        
        wvViewController?.detailItem = self.detailItem
        
        self.navigationController?.pushViewController(tabBarController!, animated: true)
    }
        
    // MARK: - Table View
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }
    
    func cookieValFromArray() -> String {
        var str = ""
        
        let cookies_tmp = UserDefaults.standard.value(forKey: "cookies")
        
        if (cookies_tmp != nil) {
            let cookies = cookies_tmp as! Dictionary<String, [HTTPCookiePropertyKey : Any]>
            
            for (key, properties) in cookies {
                str += key + "=" + (properties[HTTPCookiePropertyKey.value] as! String) + "; "
            }
        }
        
        return str
    }
    
    func httpCookieFromArray() {
        let cookies_tmp = UserDefaults.standard.value(forKey: "cookies")
        
        if (cookies_tmp != nil) {
            let cookies = cookies_tmp as! Dictionary<String, [HTTPCookiePropertyKey : Any]>
            
            for (_, properties) in cookies {
                HTTPCookieStorage.shared.setCookie(HTTPCookie.init(properties: properties)!)
            }
        }
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        NSLog("@cellForRowAt")
        
        let cellIdentifier = "DetailTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? DetailTableViewCell else {
            fatalError("The dequeued cell is not an instance of DetailTableViewCell.")
        }

        let object = objects[indexPath.row]
    
        let manager = SDWebImageManager.shared().imageDownloader
        let cookieVal = cookieValFromArray()
        
        NSLog("@cookieval: " + cookieVal + ", url: " + object.img)
        
        manager?.setValue(cookieVal, forHTTPHeaderField: "Cookie")
        httpCookieFromArray()
        
        cell.imageThumb.sd_setImage(with: URL(string: object.img)!, placeholderImage: nil, completed:{ (image, error, cacheType, url) -> Void in
            if (error != nil) {
                // set the placeholder image here
                NSLog("@cellForRowAt Error: " + error.debugDescription)
                if image == nil {
                    NSLog("@image nil")
                }
                
            } else {
                if self.objects[indexPath.row].img_height == 0 {
                    self.objects[indexPath.row].img_height = cell.frame.size.width * image!.size.height / image!.size.width
                    
                    tableView.beginUpdates()
                    tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.fade)
                    tableView.endUpdates()
                }
            }
        })
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (self.objects[indexPath.row].img_height == 0) {
            return 44
        }
        return self.objects[indexPath.row].img_height
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? DetailTableViewCell
        let originImage = cell?.imageThumb.image // some image for baseImage
        
        httpCookieFromArray()
        
        var images = [SKPhoto]()
        for idx in 0...self.objects.count-1 {
            let photo = SKPhoto.photoWithImageURL(self.objects[idx].img)
            images.append(photo)
            photo.shouldCachePhotoURLImage = true
        }
        
        let browser = SKPhotoBrowser(originImage: originImage ?? UIImage(), photos: images, animatedFromView: cell!)
        browser.initializePageIndex(indexPath.row)
        present(browser, animated: true, completion: {})
    }

    // MARK: - webview

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (keyPath == "loading") {
            // todo: what?
        }
        if (keyPath == "estimatedProgress") {
            // todo: make a loading indicator??
        }
        if (keyPath == "title") {
            title = webView.title?.decodingHTMLEntities()
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // reserved for future use
        
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void) {
        
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            completionHandler()
        }))
        
        present(alertController, animated: true, completion: nil)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        
        NSLog(error.localizedDescription)
        
        let alert = UIAlertController(title: "Error", message: "Network problem", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    
    func userContentController(_ userContentController: WKUserContentController, didReceive: WKScriptMessage) {
        
        // NSLog("@receive: " + didReceive.name)
        
        if (didReceive.name == "hkmlApp") {
            
            // receive the jsondata
            if let d = didReceive.body as? [String:Any] {
                
                if let models = d["photos"] as? [Any] {
                    if models.count == 0 {
                        self.refreshControl?.endRefreshing()
                        self.sak?.hideActivityIndicator()
                        let alert = UIAlertController(title: "注意", message: "此項目相片必須於登入後才提供，要登入嗎？", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "登入", style: .default, handler: { (action) in
                            
                            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                            let loginViewController = storyboard.instantiateViewController(withIdentifier: "loginViewContainer") as? LoginViewController
                            
                            loginViewController?.callerController = self
                            self.navigationController?.pushViewController(loginViewController!, animated: true)
                            
                            //self.tableView.reloadData()
                        }))
                        alert.addAction(UIAlertAction(title: "不登入", style: .default, handler: nil))
                        present(alert, animated: true, completion: nil)
                        return
                    }
                    
                    objects = [ImgModel]()
                    
                    if models.count > 0 {
                        for i in 0...models.count-1 {
                            let model = models[i]
                            
                            if let modelSpec = model as? [String:Any] {
                                var imgsrc = modelSpec["img"] as? String
                                
                                if (!((imgsrc?.hasPrefix("http:"))! || (imgsrc?.hasPrefix("https:"))!)) {
                                    imgsrc = path_prefix + imgsrc!
                                }
                                
                                // NSLog(imgsrc!)
                                
                                objects.append(ImgModel(
                                    title: "",
                                    img: imgsrc!,
                                    href: "",
                                    author: "",
                                    author_href: "",
                                    img_height: 0
                                ))
                            }
                            
                        }
                        
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                            self.refreshControl?.endRefreshing()
                            self.sak?.hideActivityIndicator()
                            return
                        }
                    }
                }
            }
            
        }
    }
    
    @IBAction func share(sender: UIBarButtonItem) {
        var shareUrl = detailItem?.href ?? ""
        shareUrl = shareUrl.replacingOccurrences(of: "%23", with: "#")
        let activityViewController = UIActivityViewController(
            activityItems: [shareUrl],
            applicationActivities:nil)
        
        present(activityViewController, animated: true, completion: nil)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        SDImageCache.shared().clearMemory()
    }
}

