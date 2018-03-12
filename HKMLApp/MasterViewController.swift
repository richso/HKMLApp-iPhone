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

class MasterViewController: UITableViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    
    struct Model {
        var title: String
        var img: String
        var href: String
        var author: String
        var author_href: String
    }

    var detailViewController: MultipageViewController? = nil
    var objects = [Model]()
    var webView : WKWebView!
    
    let path_prefix = "http://www.hkml.net/Discuz/"
    let mainUrl = "http://www.hkml.net/Discuz/index.php"
    let searchUrl = "http://www.hkml.net/Discuz/search.php"
    let topTenUrl = "http://www.hkml.net/Discuz/toptendetails.php?colNum=10"
    let hkmlAppJs = "https://raw.githubusercontent.com/richso/hkmlApp/master/public_html/getTopModels.js"
    let jqCDN = "http://code.jquery.com/jquery-1.12.4.min.js"
    
    var userContentController : WKUserContentController!
    
    var sak: SwissArmyKnife?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sak = SwissArmyKnife(loaderParentView: self.view)
        
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
            let scriptPath = Bundle.main.path(forResource: "getTopModels", ofType: "js")
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
        webView.load(URLRequest(url:URL(string:topTenUrl)!))

        let loginButton = UIBarButtonItem(title: "登入", style: UIBarButtonItemStyle.plain, target: self, action: #selector(goLogin(_:)))
        
        navigationItem.leftBarButtonItem = loginButton
        
        let wsButton = UIBarButtonItem(title: " ", style: UIBarButtonItemStyle.plain, target: self, action: #selector(goHome(_:)))
        
        navigationItem.rightBarButtonItem = wsButton
        
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? MultipageViewController
        }
        
    }

    @objc private func refreshTableData(_ sender: Any) {
        webView.reload()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        SDImageCache.shared().clearMemory()
    }
    
    @objc
    func goLogin(_ sender: Any) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginViewController = storyboard.instantiateViewController(withIdentifier: "loginViewContainer") as? LoginViewController
        
        self.navigationController?.pushViewController(loginViewController!, animated: true)
        
    }
    @objc
    func goHome(_ sender: Any) {
        showWebsite(urlstr: mainUrl)
    }

    public func showWebsite(urlstr: String) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let tabBarController = storyboard.instantiateViewController(withIdentifier:"tabViewController") as? UITabBarController
        
        let wvViewController = tabBarController?.viewControllers![0] as? WebviewController
        
        let model = Model(title: "", img: "", href: urlstr, author: "", author_href: "")
        
        wvViewController?.detailItem = model
        
        self.navigationController?.pushViewController(tabBarController!, animated: true)
        
    }
    
    // MARK: - Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        NSLog("segue id: " + segue.identifier!)
        
        if segue.identifier == "showDetail" {
            
            detailViewController = segue.destination as? MultipageViewController //(segue.destination as! UINavigationController).topViewController as? DetailViewController
            
            if let indexPath = tableView.indexPathForSelectedRow {
                detailViewController?.objects = objects
                detailViewController?.startIndex = indexPath.row
            }
            
            detailViewController?.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
            detailViewController?.navigationItem.leftItemsSupplementBackButton = true
        }
    }

    // MARK: - Table View
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "TopModelsTableViewCell"
        
        // NSLog("@cell")
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? TopModelsTableViewCell else {
            fatalError("The dequeued cell is not an instance of TopModelsTableViewCell.")
        }

        let object = objects[indexPath.row]
        
        cell.title.text = object.title
        //cell.imageThumb.downloadedFrom(url: URL(string: object.img)!)
        cell.imageThumb.sd_setImage(with: URL(string: object.img)!, placeholderImage: nil, completed:nil)
        
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        // reserved
    }
    
    // MARK: - webview

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (keyPath == "loading") {
            // reserved
        }
        if (keyPath == "estimatedProgress") {
            // reserved
        }
        if (keyPath == "title") {
            // reserved
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // reserve for use
        
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
        alert.addAction(UIAlertAction(title: "重新載入", style: .default, handler: { (action) in
            
            webView.load(URLRequest(url:URL(string:self.topTenUrl)!))
        }))
        present(alert, animated: true, completion: nil)
    }
    
    
    func userContentController(_ userContentController: WKUserContentController, didReceive: WKScriptMessage) {
        
        // NSLog("@receive: " + didReceive.name)
        
        if (didReceive.name == "hkmlApp") {
            
            // receive the jsondata
            if let d = didReceive.body as? [String:Any] {
                if let models = d["billboard"] as? [Any] {
                    objects = [Model]()
                    
                    for i in 0...39 {
                        let model = models[i]
                        if let modelSpec = model as? [String:Any] {
                            // NSLog(path_prefix + (modelSpec["img"] as? String)!)
                            
                            let t_title = (modelSpec["title"] as? String)!
                            
                            objects.append(Model(
                                title: t_title.decodingHTMLEntities(),
                                img: path_prefix + (modelSpec["img"] as? String)!,
                                href: path_prefix + (modelSpec["href"] as? String)!,
                                author: (modelSpec["author"] as? String)!,
                                author_href: path_prefix + (modelSpec["author_href"] as? String)!
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

