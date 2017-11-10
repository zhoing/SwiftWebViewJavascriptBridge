//
//  WebViewJavascriptBridgeBase.swift
//  Bridge
//
//  Created by ming on 2017/11/9.
//  Copyright © 2017年 TiandaoJiran. All rights reserved.
//

import Foundation
let kOldProtocolScheme = "wvjbscheme"
let kNewProtocolScheme = "https"
let kQueueHasMessage   = "__wvjb_queue_message__"
let kBridgeLoaded      = "__bridge_loaded__"

protocol WebViewJavascriptBridgeBaseDelegate: NSObjectProtocol {
    @discardableResult
    func evaluateJavascript(command: String) -> String?
}
public typealias ResponseCallback = (Any?) -> Void
public typealias Handler = (Any?, ResponseCallback?) -> Void
public typealias Message = Dictionary<String, Any>

public class WebViewJavascriptBridgeBase {
    weak var delegate: WebViewJavascriptBridgeBaseDelegate?
    public var startupMessageQueue: Array<Message> = []
    public var responseCallbacks: Dictionary<String, Any> = [:]
    public var messageHandlers: Dictionary<String, Any> = [:]
    public var messageHandler: Handler?
    private var uniqueId = 0
    static var isLogging = false
    static var logMaxLength = 500

    deinit {
        startupMessageQueue.removeAll()
        responseCallbacks.removeAll()
        messageHandlers.removeAll()

    }
    // MARK: - public method
    public class func enableLogging() {
        isLogging = true
    }
    public class func setLog(maxLength: Int) {
        logMaxLength = maxLength
    }
    public func reset() {
        startupMessageQueue.removeAll()
        responseCallbacks.removeAll()
        uniqueId = 0
    }
    public func send(_ data: Any?, response callback: ResponseCallback? = nil, handler name: String? = nil) {
        if data == nil {
            return
        }
        var message: Dictionary<String, Any> = [:]
        message["data"] = data!
        if callback != nil {
            let callbackId = "objc_cb_\(uniqueId)"
            self.responseCallbacks[callbackId] = callback!
            message["callbackId"] = callbackId
        }
        if name != nil {
            message["handlerName"] = name!
        }
        queueMessage(message)
    }
    public func flush(_ messageQueue: String?) {
        if messageQueue == nil && messageQueue?.count == 0 {
            debugPrint("WebViewJavascriptBridge: WARNING: ObjC got nil while fetching the message queue JSON from webview. This can happen if the WebViewJavascriptBridge JS is not currently present in the webview, e.g if the webview just loaded a new page.")
            return
        }
        let messages = deserialize(messageQueue!) ?? []
        for message in messages {
            log("RCVD", json: message)
            let responseId = message["responseId"] as? String
            if responseId != nil {
                let responseCallback = responseCallbacks[responseId!] as? ResponseCallback
                if responseCallback != nil {
                    responseCallback!(message["responseData"])
                }
                responseCallbacks.removeValue(forKey: responseId!)
            } else {
                var responseCallback: ResponseCallback? = nil
                let callbackId = message["callbackId"] as? String
                if callbackId != nil {
                    responseCallback = {[weak self](responseData) in
                        let msg = ["responseId": callbackId!, "responseData": responseData ?? NSNull()]
                        self?.queueMessage(msg)
                    }
                } else {
                    responseCallback = {(responseData) in
                    }
                }
                let handler = messageHandlers[(message["handlerName"] as? String) ?? ""] as? Handler
                if handler != nil {
                    handler!(message["data"], responseCallback)
                } else {
                    debugPrint("WVJBNoHandlerException, No handler for message from JS: %@", message.description)
                }
            }
        }
    }
    public func injectJavascriptFile() {

        evaluateJavascript(preprocessorJSCode)
        if startupMessageQueue.count != 0 {
            for queuedMessage in startupMessageQueue {
                dispatchMessage(queuedMessage)
            }
            startupMessageQueue = []
        }
    }

    public func isWebViewJavascriptBridge(url: URL) -> Bool {
        if isSchemeMatch(url){
            return self.isBridgeLoaded(url) || self.isQueueMessage(url)
        }
        return false
    }
    public func isQueueMessage(_ url: URL) -> Bool {
        let host = url.host?.lowercased()
        return self.isSchemeMatch(url) && host == kQueueHasMessage
    }
    public func isBridgeLoaded(_ url: URL) -> Bool {
        let host = url.host?.lowercased()
        return self.isSchemeMatch(url) && host == kBridgeLoaded
    }
    public func logUnkownMessage(_ url: URL) {
        debugPrint("WebViewJavascriptBridge: WARNING: Received unknown WebViewJavascriptBridge command", url.absoluteString)
    }
    public func webViewJavascriptCheckCommand() -> String {
        return "typeof WebViewJavascriptBridge == \'object\';"
    }
    public func webViewJavascriptFetchQueyCommand() -> String {
        return "WebViewJavascriptBridge._fetchQueue();"
    }
    public func disableJavscriptAlertBoxSafetyTimeout() {
        send(nil, response: nil, handler: "disableJavascriptAlertBoxSafetyTimeout")
    }
    // MARK: - private method

    func isSchemeMatch(_ url: URL) -> Bool {
        let scheme = url.scheme?.lowercased()
        return scheme == kNewProtocolScheme || scheme == kOldProtocolScheme
    }

    @discardableResult
    private func evaluateJavascript(_ command: String) -> String? {
        return self.delegate?.evaluateJavascript(command: command)
    }

    private func queueMessage(_ message: Message) {
        if startupMessageQueue.count == 0 {
            dispatchMessage(message)
        } else {
            startupMessageQueue.append(message)
        }
    }

    private func dispatchMessage(_ message: Message) {
        var messageJSON = serialize(message, pretty: false)
        log("SEND", json: messageJSON)

        messageJSON = messageJSON.replacingOccurrences(of: "\\", with: "\\\\")
        messageJSON = messageJSON.replacingOccurrences(of: "\"", with: "\\\"")
        messageJSON = messageJSON.replacingOccurrences(of: "\'", with: "\\\'")
        messageJSON = messageJSON.replacingOccurrences(of: "\n", with: "\\n")
        messageJSON = messageJSON.replacingOccurrences(of: "\r", with: "\\r")
        messageJSON = messageJSON.replacingOccurrences(of: "\u{000C}", with: "\\u{000C}")
        messageJSON = messageJSON.replacingOccurrences(of: "\u{2028}", with: "\\u{2028}")
        messageJSON = messageJSON.replacingOccurrences(of: "\u{2029}", with: "\\u{2029}")

        let javascriptCommand = String.init(format: "WebViewJavascriptBridge._handleMessageFromObjC('%@');", messageJSON)
        DispatchQueue.main.async {
            self.evaluateJavascript(javascriptCommand)
        }
    }


    private func deserialize(_ messageJSON: String) -> Array<Message>? {
        guard let data = messageJSON.data(using: .utf8) else { return nil }
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
            if json is Array<Message>{
                return json as? Array<Message>
            }
            return nil
        } catch  {
            return nil
        }
    }
    private func log(_ action: String, json: Any) {
        if !WebViewJavascriptBridgeBase.isLogging {
            return
        }
        var jsonStr = ""
        if !(json is String) {
            jsonStr = serialize(json, pretty: true)
        } else {
            jsonStr = json as! String
        }
        if jsonStr.count > WebViewJavascriptBridgeBase.logMaxLength {
            debugPrint("WebViewJavascriptBridge" + action + jsonStr[..<jsonStr.index(jsonStr.startIndex, offsetBy: WebViewJavascriptBridgeBase.logMaxLength)])
        } else {
            debugPrint("WebViewJavascriptBridge" + action + jsonStr)
        }
    }
    private func serialize(_ message: Any, pretty: Bool) -> String {
        do {
            let json = try JSONSerialization.data(withJSONObject: message, options: pretty ? JSONSerialization.WritingOptions.prettyPrinted : JSONSerialization.WritingOptions.init(rawValue: 0))
            return String.init(data: json, encoding: .utf8) ?? ""
        } catch  {
            return ""
        }
    }
}
