//
//  ViewController.swift
//  SwiftWebViewJavascriptBridge
//
//  Created by ming on 11/10/2017.
//  Copyright (c) 2017 ming. All rights reserved.
//

import UIKit
import SwiftWebViewJavascriptBridge

class ViewController: UIViewController {
    var webView = UIWebView.init()


    override func viewDidLoad() {
        super.viewDidLoad()
        let bridge = WebViewJavascriptBridge.init(webView: webView)
        bridge.register("logoutTime") {(data, responseCall) in
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ReLgoinNotification"), object: nil)
        }
        bridge.send(["name": "tome", "age": 16, "uid": 0], response: { (data) in
            debugPrint("response",data ?? "");
        }, handler: "setParams")
        bridge.call("setParams", data: ["X-token": "1234567890", "X-ui": "1", "X-macid": "123456789"]) { (data) in
            debugPrint("response",data ?? "");
        }
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

