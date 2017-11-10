//
//  WebViewJavascriptBridge.swift
//  Bridge
//
//  Created by ming on 2017/11/9.
//  Copyright © 2017年 TiandaoJiran. All rights reserved.
//

import Foundation

#if os(macOS)
    import Cocoa
    import WebKit
#else
    import UIKit
#endif
#if os(macOS)
    public typealias SwiftWebViewType = WebView
    public typealias SwiftWebViewDelegateType = WebPolicyDelegate
#else
    public typealias SwiftWebViewType = UIWebView
    public typealias SwiftWebViewDelegateType = UIWebViewDelegate
#endif


open class WebViewJavascriptBridge: NSObject, WebViewJavascriptBridgeBaseDelegate,WebViewJavaScriptBridgeProtocol {
    public typealias WebViewType = SwiftWebViewType
    public typealias WebViewDelegateType = SwiftWebViewDelegateType

    public weak var webView: WebViewType?
    public weak var webViewDelegate: WebViewDelegateType?
    public var base = WebViewJavascriptBridgeBase()
    private var uniqueId = 0
// MARK: - public method
    public required init(webView: UIWebView) {
        super.init()
        self.webView = webView
#if os(macOS)
    self.webView?.policyDelegate = self
#else
    self.webView?.delegate = self
#endif
        base = WebViewJavascriptBridgeBase()
        base.delegate = self
    }
    deinit {
#if os(macOS)
    webView?.policyDelegate = self
#else
    webView?.delegate = nil
#endif
        webView = nil
        webViewDelegate = nil
    }
    // MARK: - WebViewJavascriptBridgeBaseDelegate

    @discardableResult
    func evaluateJavascript(command: String) -> String? {
        return webView?.stringByEvaluatingJavaScript(from: command)
    }
}

extension WebViewJavascriptBridge: SwiftWebViewDelegateType {
#if os(macOS)
    // MARK: - SwiftWebViewJavaScriptBridgeBaseDelegate
    public func webView(_ webView: WebView!, decidePolicyForNavigationAction actionInformation: [AnyHashable: Any]!, request: URLRequest!, frame: WebFrame!, decisionListener listener: WebPolicyDecisionListener!) {
        if webView != self.webView {
            return true
        }
        guard let url = request.url else { return }
        if base.isWebViewJavascriptBridge(url: url) {
            if base.isBridgeLoaded(url: url) {
                base.injectJavascriptFile()
            } else if base?.isQueueMessage(url: url) {
                let messageQueueString = evaluateJavascript(command: base.webViewJavascriptFetchQueyCommand())
                base.flush(messageQueueString: messageQueueString)
            } else {
                base.logUnkownMessage(url: url)
            }
            listener.ignore()
        }else if let webViewDelegate = self.webViewDelegate as? WebPolicyDelegate,webViewDelegate.responds(to: #selector(webView(_:decidePolicyForNavigationAction:request:frame:decisionListener:))) {
            webViewDelegate.webView?(webView, decidePolicyForNavigationAction: actionInformation, request: request, frame: frame, decisionListener: listener)
        } else {
            listener.use()
        }
    }

    public func webView(_ webView: WebView!, decidePolicyForNewWindowAction actionInformation: [AnyHashable : Any]!, request: URLRequest!, newFrameName frameName: String!, decisionListener listener: WebPolicyDecisionListener!) {
        if webView != self.webView {
            return
        }
        if webViewDelegate != nil && webViewDelegate?.responds(to: #selector(webViewDelegate?.webView(_:decidePolicyForNewWindowAction:request:newFrameName:decisionListener:))) == true {
            webViewDelegate?.webView?(webView, decidePolicyForNewWindowAction: actionInformation, request: request, newFrameName: frameName, decisionListener: listener)
            }
    }

        public func webView(_ webView: WebView!, decidePolicyForMIMEType type: String!, request: URLRequest!, frame: WebFrame!, decisionListener listener: WebPolicyDecisionListener!) {
        if webView != self.webView {
            return
        }
        if webViewDelegate != nil && webViewDelegate?.responds(to: #selector(webViewDelegate?.webView(_:decidePolicyForMIMEType:request:frame:decisionListener:))) == true {
            webViewDelegate?.webView?(webView, decidePolicyForMIMEType: type, request: request, frame: frame, decisionListener: listener)
        }

    }

    public func webView(_ webView: WebView!, unableToImplementPolicyWithError error: Error!, frame: WebFrame!) {
        if webView != self.webView {
            return
        }
        if webViewDelegate != nil && webViewDelegate?.responds(to: #selector(webViewDelegate?.webView(_:unableToImplementPolicyWithError:frame:))) == true {
            webViewDelegate?.webView?(webView, unableToImplementPolicyWithError: error, frame: frame)
        }
    }

#else
    // MARK: - UIWebViewDelegate

    public func webViewDidFinishLoad(_ webView: UIWebView) {
        if webView != self.webView {
            return
        }
        if webViewDelegate != nil && webViewDelegate?.responds(to: #selector(webViewDelegate?.webViewDidFinishLoad(_:))) == true {
            webViewDelegate?.webViewDidFinishLoad?(webView)
        }
    }
    public func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        if webView != self.webView {
            return
        }
        if webViewDelegate != nil && webViewDelegate?.responds(to: #selector(webViewDelegate?.webView(_:didFailLoadWithError:))) == true {
            webViewDelegate?.webView?(webView, didFailLoadWithError: error)
        }
    }
    public func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if webView != self.webView {
            return true
        }
        let url = request.url ?? URL.init(fileURLWithPath: "")
        if base.isWebViewJavascriptBridge(url: url) {
            if base.isBridgeLoaded(url) {
                base.injectJavascriptFile()
            } else if base .isQueueMessage(url) {
                let messageQueueString = evaluateJavascript(command: base.webViewJavascriptFetchQueyCommand())
                base.flush(messageQueueString)
            } else {
                base.logUnkownMessage(url)
            }
            return false
        } else if webViewDelegate != nil && webViewDelegate?.responds(to: #selector(webViewDelegate?.webView(_:shouldStartLoadWith:navigationType:))) == true {
            return webViewDelegate!.webView!(webView, shouldStartLoadWith: request, navigationType: navigationType)
        } else {
            return true
        }
    }
    public func webViewDidStartLoad(_ webView: UIWebView) {
        if webView != self.webView {
            return
        }
        if webViewDelegate != nil && webViewDelegate?.responds(to: #selector(webViewDelegate?.webViewDidStartLoad(_:))) == true {
            webViewDelegate?.webViewDidStartLoad?(webView)
        }
    }
#endif
}

