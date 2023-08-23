//
//  MultipageViewController.swift
//  HKMLApp
//
//  Created by Richard So on 3/1/2018.
//  Copyright © 2018 Netrogen Creative. All rights reserved.
//

import UIKit
import SDWebImage
import WebKit

class MultipageViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    var pageViewController: UIPageViewController?
    var objects = [MasterViewController.Model]()
    var startIndex: NSInteger!
    var lastPendingViewControllerIndex: NSInteger?
    var currentPageIndex: Int?
    
    var wkProcessPool: WKProcessPool!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSLog("@MultipageViewController here")
        
        self.pageViewController = self.storyboard?.instantiateViewController(withIdentifier:"PageViewController") as? UIPageViewController
        self.pageViewController?.dataSource = self
        
        self.pageViewController?.delegate = self
        
        let startingViewController = self.viewControllerAtIndex(startIndex)
        let viewControllers: [UIViewController] = [startingViewController!]
        self.pageViewController?.setViewControllers(viewControllers, direction: UIPageViewController.NavigationDirection.forward, animated: false, completion: nil)
        
        self.title = objects[startIndex].title
        self.currentPageIndex = startIndex;
        
        self.addChild(self.pageViewController!)
        self.view.addSubview((self.pageViewController?.view)!)
        self.pageViewController?.didMove(toParent: self)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]){
        
        if let viewController = pendingViewControllers[0] as? DetailViewController {
            
            self.lastPendingViewControllerIndex = viewController.pageIndex
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        if completed{
            self.currentPageIndex = lastPendingViewControllerIndex!
            
            SDImageCache.shared.clearMemory()
            
            NSLog("@obj title: " + objects[lastPendingViewControllerIndex!].title)
            self.title = objects[lastPendingViewControllerIndex!].title
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        var index = (viewController as! DetailViewController).pageIndex
        
        if ((index == 0) || (index == NSNotFound)) {
            return nil;
        }
        
        index = index! - 1;
        return self.viewControllerAtIndex(index!);
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        var index = (viewController as! DetailViewController).pageIndex
        
        if (index == NSNotFound) {
            return nil;
        }
        
        index = index! + 1;
        if (index == self.objects.count) {
            return nil;
        }
        return self.viewControllerAtIndex(index!);
    }
    
    func viewControllerAtIndex(_ index: NSInteger) -> UIViewController? {
        if self.objects.count == 0 || index >= self.objects.count {
            return nil
        }
        
        let pageContentViewController = self.storyboard?.instantiateViewController(withIdentifier: "DetailViewController") as! DetailViewController
        
        pageContentViewController.detailItem = self.objects[index]
        pageContentViewController.pageIndex = index
        pageContentViewController.multiController = self
        pageContentViewController.wkProcessPool = self.wkProcessPool
        
        return pageContentViewController
    }
    
}
