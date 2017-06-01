//
//  ViewController.swift
//  Example
//
//  Created by 丁帅 on 2017/5/31.
//  Copyright © 2017年 M_M. All rights reserved.
//

import UIKit
@testable import MMCache

private let id = "ExampleID"

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        CacheObject.clean(identifer: id)
        
        let cache = CacheObject.insert(with: "foo", identifer: id, path: "/foo", dataSize: 1024, expriedInterval: 100)
        
        let result = CacheObject.get(with: "foo", identifer: id)

        
        print(cache.path as Any)
        print(result?.path as Any)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

