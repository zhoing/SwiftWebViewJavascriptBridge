//
//  WebViewJavaScriptBridgeProtocol.swift
//  Bridge
//
//  Created by ming on 2017/11/10.
//  Copyright © 2017年 TiandaoJiran. All rights reserved.
//

import Foundation

public protocol WebViewJavaScriptBridgeProtocol {
    var base: WebViewJavascriptBridgeBase { get }
    associatedtype WebViewType
    init(webView: WebViewType)
    var webView: WebViewType? { get set }

    associatedtype WebViewDelegateType
    var webViewDelegate: WebViewDelegateType? { get set }

    static var isLogging: Bool { get set }
    static var logMaxLength: Int { get set }
}
extension WebViewJavaScriptBridgeProtocol {
    // MARK: - Public methods
    public static var isLogging: Bool {
        get {
            return WebViewJavascriptBridgeBase.isLogging
        }
        set {
            WebViewJavascriptBridgeBase.isLogging = newValue
        }
    }

    public static var logMaxLength: Int {
        get {
            return WebViewJavascriptBridgeBase.logMaxLength
        }
        set {
            WebViewJavascriptBridgeBase.logMaxLength = newValue
        }
    }
    public func register(_ name: String, handler: Handler? = nil) {
        base.messageHandlers[name] = handler
    }

    public func remove(_ name: String) {
        base.messageHandlers.removeValue(forKey: name)
    }

    public func call(_ name: String, data: Any? = nil, response callback: ResponseCallback? = nil) {
        base.send(data, response: callback, handler: name)
    }

    public func send(_ data: Any?, response callback: ResponseCallback? = nil, handler name: String? = nil) {
        base.send(data, response: callback, handler: name)
    }

    public func reset() {
        base.reset()
    }
    public func disableJavscriptAlertBoxSafetyTimeout() {
        base.disableJavscriptAlertBoxSafetyTimeout()
    }
}
