//
//  MasterViewController.swift
//  test_master_detail
//
//  Created by Richard So on 24/11/2017.
//  Copyright © 2017 Netrogen Creative. All rights reserved.
//

import UIKit
import WebKit

class MasterViewController: UITableViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    
    struct Model {
        var title: String
        var img: String
        var href: String
        var author: String
        var author_href: String
    }

    var detailViewController: DetailViewController? = nil
    var objects = [Model]()
    var webView : WKWebView!
    
    let path_prefix = "http://www.hkml.net/Discuz/"
    let mainUrl = "http://www.hkml.net/Discuz/index.php"
    let searchUrl = "http://www.hkml.net/Discuz/search.php"
    let topTenUrl = "http://www.hkml.net/Discuz/toptendetails.php"
    let hkmlAppJs = "https://raw.githubusercontent.com/richso/hkmlApp/master/public_html/getTopModels.js"
    let jqCDN = "http://code.jquery.com/jquery-1.12.4.min.js"
    
    var userContentController : WKUserContentController!
    
    var spinner = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    var loadingView: UIView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        refreshControl = UIRefreshControl()
        tableView.addSubview(refreshControl!)
        refreshControl?.addTarget(self, action: #selector(refreshTableData(_:)), for: .valueChanged)

        let config = WKWebViewConfiguration()
        userContentController = WKUserContentController()
        config.userContentController = userContentController
        webView = WKWebView(frame: CGRect.zero, configuration: config)
        
        self.view.addSubview(webView)
        
        userContentController.add(self, name: "hkmlApp")
        
        var jquery = try? String(contentsOf: URL(string: jqCDN)!, encoding: String.Encoding.utf8)
        jquery = (jquery!) + " $j=jQuery.noConflict();";
        let jqScript = WKUserScript(source: jquery!, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        config.userContentController.addUserScript(jqScript)
        
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
        
        showActivityIndicator()
        webView.load(URLRequest(url:URL(string:topTenUrl)!))

        let wsButton = UIBarButtonItem(title: "到網站", style: UIBarButtonItemStyle.plain, target: self, action: #selector(goHome(_:)))
        
        navigationItem.rightBarButtonItem = wsButton
        
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
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
    }
    
    @objc
    func goHome(_ sender: Any) {
        showWebsite(urlstr: mainUrl)
    }

    func showWebsite(urlstr: String) {
        if (self.detailViewController != nil) {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let wvViewController = storyboard.instantiateViewController(withIdentifier: "webViewContainer") as? ViewController
            
            let model = Model(title: "", img: "", href: urlstr, author: "", author_href: "")
            
            wvViewController?.detailItem = model
            self.navigationController?.pushViewController(wvViewController!, animated: true)
        }
    }
    
    // MARK: - Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        NSLog("segue id: " + segue.identifier!)
        
        if segue.identifier == "showDetail" {
            
            detailViewController = (segue.destination as! UINavigationController).topViewController as? DetailViewController
            
            if let indexPath = tableView.indexPathForSelectedRow {
                let object = objects[indexPath.row]
                
                detailViewController?.detailItem = object
            } else {
                var urlstr = mainUrl
                if sender as! String == "searchButton" {
                    urlstr = searchUrl
                }
                let model = Model(title: "", img: "", href: urlstr, author: "", author_href: "")
                
                detailViewController?.detailItem = model
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? TopModelsTableViewCell else {
            fatalError("The dequeued cell is not an instance of TopModelsTableViewCell.")
        }

        let object = objects[indexPath.row]
        
        cell.title.text = object.title
        cell.imageThumb.downloadedFrom(url: URL(string: object.img)!)
        
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            objects.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
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
            // todo: what??
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
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    
    func userContentController(_ userContentController: WKUserContentController, didReceive: WKScriptMessage) {
        
        NSLog("@receive: " + didReceive.name)
        
        if (didReceive.name == "hkmlApp") {
            
            // receive the jsondata
            if let d = didReceive.body as? [String:Any] {
                if let models = d["billboard"] as? [Any] {
                    objects = [Model]()
                    
                    for i in 0...19 {
                        let model = models[i]
                        if let modelSpec = model as? [String:Any] {
                            NSLog(path_prefix + (modelSpec["img"] as? String)!)
                            
                            objects.append(Model(
                                title: (modelSpec["title"] as? String)!,
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
                        self.hideActivityIndicator()
                        return
                    }
                }
            }
            
        }
    }
    
    func showActivityIndicator() {
        DispatchQueue.main.async {
            self.loadingView = UIView()
            self.loadingView.frame = CGRect(x: 0.0, y: 0.0, width: 100.0, height: 100.0)
            self.loadingView.center = self.view.center
            self.loadingView.backgroundColor = UIColor(red: 0.26, green: 0.26, blue: 0.26, alpha: 0.7)
            //self.loadingView.alpha = 0.7
            self.loadingView.clipsToBounds = true
            self.loadingView.layer.cornerRadius = 10
            
            self.spinner = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
            self.spinner.frame = CGRect(x: 0.0, y: 0.0, width: 80.0, height: 80.0)
            self.spinner.center = CGPoint(x:self.loadingView.bounds.size.width / 2, y:self.loadingView.bounds.size.height / 2)
            
            self.loadingView.addSubview(self.spinner)
            self.view.addSubview(self.loadingView)
            self.spinner.startAnimating()
        }
    }
    
    func hideActivityIndicator() {
        DispatchQueue.main.async {
            self.spinner.stopAnimating()
            self.loadingView.removeFromSuperview()
        }
    }
}

