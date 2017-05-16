//
//  ViewController.swift
//  Cache
//
//  Created by 丁帅 on 2017/3/22.
//  Copyright © 2017年 丁帅. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        if let cache = CacheObject.get(with: "foo") {
            print("get:  ", cache.last_update_time as Any)
            cache.last_update_time = Date() as NSDate
            CacheObject.save()
        } else {
            let cache = CacheObject.insert()
            cache.key = "foo"
            cache.size = 123456
            cache.path = "/foo"
            cache.last_update_time = Date() as NSDate
            print("insert:  ", cache.last_update_time!)
            CacheObject.save()
        }
        
        let result = CacheObject.get(with: "foo")
        print("result:  ", result!.last_update_time!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

