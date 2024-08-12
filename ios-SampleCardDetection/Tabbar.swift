//
//  Tabbar.swift
//  ios-SampleCardDetection
//
//  Created by Necati Alperen IŞIK on 11.08.2024.
//

import UIKit

class TabbarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabbar()
    }
    
    private func setupTabbar() {
        tabBar.backgroundColor = .systemGray3
        
        let scannerViewController = ScannerViewController()
        
        let vc = UINavigationController(rootViewController: scannerViewController)
        vc.tabBarItem.image = UIImage(systemName: "camera.viewfinder")
        vc.tabBarItem.title = "Scan"
        
        tabBar.tintColor = .label
        setViewControllers([vc], animated: true)
    }
}
