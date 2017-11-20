# SwiftWebViewJavascriptBridge

[![CI Status](http://img.shields.io/travis/ming/SwiftWebViewJavascriptBridge.svg?style=flat)](https://travis-ci.org/ming/SwiftWebViewJavascriptBridge)
[![Version](https://img.shields.io/cocoapods/v/SwiftWebViewJavascriptBridge.svg?style=flat)](http://cocoapods.org/pods/SwiftWebViewJavascriptBridge)
[![License](https://img.shields.io/cocoapods/l/SwiftWebViewJavascriptBridge.svg?style=flat)](http://cocoapods.org/pods/SwiftWebViewJavascriptBridge)
[![Platform](https://img.shields.io/cocoapods/p/SwiftWebViewJavascriptBridge.svg?style=flat)](http://cocoapods.org/pods/SwiftWebViewJavascriptBridge)

Swift version of [WebViewJavascriptBridge](https://github.com/marcuswestin/WebViewJavascriptBridge) with more simplified, friendly methods to send messages between Swift and JS in UIWebViews.

---

#### Cocoapods(iOS8+)


1. Add these lines below to your Podfile

```
platform :ios, '8.0'
use_frameworks!
pod 'SwiftWebViewBridge'
```
2. Install the pod by running `pod install`
3. import SwiftWebViewBridge

#### Manually(iOS8+)

Drag `SwiftWebViewJavascriptBridge` file to your project.

1. Xcode9.0+
2. iOS8.0+

### General

1. initialize a bridge with defaultHandler
2. register handlers to handle different events
3. send data / call handler on both sides

### For Swift

Generate a bridge with associated webView
```
let bridge = WebViewJavascriptBridge.init(webView: webView)
```
##### func registerHandlerForJS(handlerName name: String, handler:SWVBHandler)
Register a handler for JavaScript calling

```
// take care of retain cycle!
bridge.register("logoutTime") {(data, responseCall) in
NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ReLgoinNotification"), object: nil)
}
```
##### func send(_ data: Any?, response callback: ResponseCallback? = nil, handler name: String? = nil)

```
bridge.send(["name": "tome", "age": 16, "uid": 0], response: { (data) in
debugPrint("response",data ?? "");
}, handler: "setParams")
```
#####  func call(_ name: String, data: Any? = nil, response callback: ResponseCallback? = nil) Call JavaScript registered handler

```
bridge.call("setParams", data: ["X-token": "1234567890", "X-ui": "1", "X-macid": "123456789"]) { (data) in
debugPrint("response",data ?? "");
}
```
##### typealias mentioned above

```
/// 1st param: responseData to JS
public typealias ResponseCallback = (Any?) -> Void
/// 1st param: jsonData sent from JS; 2nd param: responseCallback for sending
public typealias Handler = (Any?, ResponseCallback?) -> Void
public typealias Message = Dictionary<String, Any>

```

##### logging for debug

```
WebViewJavascriptBridge.logging = false  //default true
```

### For JavaScript

##### function init(defaultHandler)

```
bridge.init(function(message, responseCallback) {
log('JS got a message', message)
var data = { 'JS Responds' : 'Message received = )' }
responseCallback(data)
})
```
##### function registerHandlerForSwift(handlerName, handler)

```
bridge.registerHandlerForSwift('alertReceivedParmas', function(data, responseCallback) {
log('ObjC called alertPassinParmas with', JSON.stringify(data))
alert(JSON.stringify(data))
var responseData = { 'JS Responds' : 'alert triggered' }
responseCallback(responseData)
})
```

##### function sendDataToSwift(data, responseCallback)

```
bridge.sendDataToSwift('Say Hello Swiftly to Swift')
bridge.sendDataToSwift('Hi, anybody there?', function(responseData){
alert("got your response: " + JSON.stringify(responseData))
})
```

##### function callSwiftHandler(handlerName, data, responseCallback)

```
SwiftWebViewBridge.callSwiftHandler("printReceivedParmas", {"name": "小明", "age": "6", "school": "GDUT"}, function(responseData){
log('JS got responds from Swift: ', responseData)
})
```

## License

SwiftWebViewJavascriptBridge is available under the MIT license. See the LICENSE file for more info.
