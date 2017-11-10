//
//  WKWebViewJavascriptBridge.swift
//  Bridge
//
//  Created by ming on 2017/11/9.
//  Copyright © 2017年 TiandaoJiran. All rights reserved.
//

import Foundation
import WebKit

open class WKWebViewJavascriptBridge: NSObject, WebViewJavascriptBridgeBaseDelegate, WebViewJavaScriptBridgeProtocol {
    public typealias WebViewType = WKWebView
    public typealias WebViewDelegateType = WKNavigationDelegate

    public weak var webView: WebViewType?
    public weak var webViewDelegate: WebViewDelegateType?
    public var base = WebViewJavascriptBridgeBase()
    private var uniqueId = 0
// MARK: - public method
    public required init(webView: WKWebView) {
        super.init()
        self.webView = webView
        self.webView?.navigationDelegate = self
        base.delegate = self
    }
    deinit {
        webView?.navigationDelegate = nil
        webView = nil
        webViewDelegate = nil
    }
// MARK: - WebViewJavascriptBridgeBaseDelegate
    @discardableResult
    func evaluateJavascript(command: String) -> String? {
        webView?.evaluateJavaScript(command, completionHandler: nil)
        return nil
    }
// MARK: - private method
    open func WKFlushMessageQueue() {
        if webView == nil {
            return
        }
        webView?.evaluateJavaScript(base.webViewJavascriptFetchQueyCommand(), completionHandler: { (result, error) in

            if error != nil {
                print("WebViewJavascriptBridge: WARNING: Error when trying to fetch data from WKWebView: ", error?.localizedDescription ?? "")
            }
            self.base.flush(result as? String)
        })
    }
}
// MARK: - WKNavigationDelegate
extension WKWebViewJavascriptBridge: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if webView != self.webView {
            return
        }
        if webViewDelegate != nil && webViewDelegate?.responds(to: #selector(webViewDelegate?.webView(_:didFinish:))) == true {
            webViewDelegate?.webView?(webView, didFinish: navigation)
        }
    }
    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if webView != self.webView {
            return
        }
        typealias WKNavigationActionMethodType = (WKWebView,WKNavigationResponse,@escaping(WKNavigationResponsePolicy)->Void) -> Void
        if (webViewDelegate?.responds(to: #selector(webView(_:decidePolicyFor:decisionHandler:) as WKNavigationActionMethodType)))! {
            webViewDelegate?.webView?(webView, decidePolicyFor: navigationResponse, decisionHandler: decisionHandler)
        } else {
            decisionHandler(.allow)
        }
    }

    public func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if webView != self.webView {
            return
        }
        if webViewDelegate != nil && webViewDelegate?.responds(to: #selector(webViewDelegate?.webView(_:didReceive:completionHandler:))) == true {
            webViewDelegate?.webView?(webView, didReceive: challenge, completionHandler: completionHandler)
        }
    }
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if webView != self.webView{
            return
        }
        let url = navigationAction.request.url ?? URL.init(fileURLWithPath: "")

        if base.isWebViewJavascriptBridge(url: url) {
            if base.isBridgeLoaded(url) {
                base.injectJavascriptFile()
            } else if base.isQueueMessage(url) {
                WKFlushMessageQueue()
            } else {
                base.logUnkownMessage(url)
            }
            decisionHandler(.cancel)
        }

        typealias WKNavigationActionMethodType = (WKWebView,WKNavigationAction,@escaping(WKNavigationActionPolicy)->Void) -> Void
        if (webViewDelegate?.responds(to: #selector(webView(_:decidePolicyFor:decisionHandler:) as WKNavigationActionMethodType)))! {
            webViewDelegate?.webView?(webView, decidePolicyFor: navigationAction, decisionHandler: decisionHandler)
        } else {
            decisionHandler(.allow)
        }
    }
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if webView != self.webView {
            return
        }
        if webViewDelegate != nil && webViewDelegate?.responds(to: #selector(webViewDelegate?.webView(_:didStartProvisionalNavigation:))) == true {
            webViewDelegate?.webView?(webView, didStartProvisionalNavigation: navigation)
        }
    }
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if webView != self.webView {
            return
        }
        if webViewDelegate != nil && webViewDelegate?.responds(to: #selector(webViewDelegate?.webView(_:didFail:withError:))) == true {
            webViewDelegate?.webView?(webView, didFail: navigation, withError: error)
        }
    }
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if webView != self.webView {
            return
        }
        if webViewDelegate != nil && webViewDelegate?.responds(to: #selector(webViewDelegate?.webView(_:didFailProvisionalNavigation:withError:))) == true {
            webViewDelegate?.webView?(webView, didFailProvisionalNavigation: navigation, withError: error)
        }
    }
    public func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        if webView != self.webView {
            return
        }
        if webViewDelegate != nil && webViewDelegate?.responds(to: #selector(webViewDelegate?.webView(_:didReceiveServerRedirectForProvisionalNavigation:))) == true {
            webViewDelegate?.webView?(webView, didReceiveServerRedirectForProvisionalNavigation: navigation)
        }
    }
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if webView != self.webView {
            return
        }
        if webViewDelegate != nil && webViewDelegate?.responds(to: #selector(webViewDelegate?.webView(_:didCommit:))) == true {
            webViewDelegate?.webView?(webView, didCommit: navigation)
        }
    }
    @available(iOS 9.0, *)
    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        if webView != self.webView {
            return
        }
        if webViewDelegate != nil && webViewDelegate?.responds(to: #selector(webViewDelegate?.webViewWebContentProcessDidTerminate(_:))) == true {
            webViewDelegate?.webViewWebContentProcessDidTerminate?(webView)
        }
    }
}
