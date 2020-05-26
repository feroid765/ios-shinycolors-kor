import UIKit
import WebKit
import Foundation

class FullScreenWKWebView: WKWebView, UIGestureRecognizerDelegate {
    override var safeAreaInsets: UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    @objc func viewTap() {
        let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache, WKWebsiteDataTypeCookies])
        let date = NSDate(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set, modifiedSince: date as Date, completionHandler:{ })
        self.reload()
    }
    
}

class ViewController: UIViewController,WKUIDelegate, UIGestureRecognizerDelegate, WKNavigationDelegate {
    
    var webView: FullScreenWKWebView!
    
    @objc func viewTap() {
        let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache, WKWebsiteDataTypeCookies])
        let date = NSDate(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set, modifiedSince: date as Date, completionHandler:{ })
        webView.reload()
    }
    
    func setApplicationDefault() {
        let stanDefaults = UserDefaults.standard
        let appDefaults = ["reminder_pref": true]
        stanDefaults.register(defaults: appDefaults)
        stanDefaults.synchronize()
    }
    
    func query(address: String) -> String {
        // original : https://gist.github.com/groz/85b95f663f79ba17946269ea65c2c0f4
        let url = URL(string: address)
        let semaphore = DispatchSemaphore(value: 0)
        
        var result: String = ""
        
        let task = URLSession.shared.dataTask(with: url!) {(data, response, error) in
            result = String(data: data!, encoding: String.Encoding.utf8)!
            semaphore.signal()
        }
        
        task.resume()
        semaphore.wait()
        return result
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
      return true
    }
    
    
    override func loadView(){
        setApplicationDefault()
        let userSettings = UserDefaults.standard
        
        var addr:String = "https://newbiepr.github.io/shinymaskr/ShinyColors.user.js"
        if(userSettings.bool(forKey: "change_script_url")){
            let userAdd = userSettings.string(forKey: "script_url")
            if(userAdd != nil){
                addr = userAdd!
            }
        }
        
        let content = query(address : addr)
        let webConfig = WKWebViewConfiguration()
        let webPref = WKPreferences()
        let script = WKUserScript(source:content, injectionTime:.atDocumentEnd, forMainFrameOnly: false)
        let contentController = WKUserContentController()
        contentController.addUserScript(script)
        webConfig.userContentController = contentController
        
        webPref.javaScriptEnabled = true
        webConfig.allowsInlineMediaPlayback = true
        webConfig.mediaTypesRequiringUserActionForPlayback = []
        webConfig.preferences = webPref

        webView = FullScreenWKWebView(frame:.zero, configuration: webConfig)
        webView.allowsBackForwardNavigationGestures = true
        webView.uiDelegate = self
        webView.navigationDelegate = self
        
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.98 Safari/537.36"
        let tapGesture = UIRotationGestureRecognizer(target: self, action: #selector(viewTap) )
        tapGesture.delegate = self
        view = webView
        view.addGestureRecognizer(tapGesture)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let myURL = URL(string:"https://shinycolors.enza.fun/")
        webView.load(URLRequest(url: myURL!))
    }
    
    
    //아이패드 렉 완화 => 아이폰에서는 지우고 사용하길 권장.
    @available(iOS 13.0, *)
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        preferences.preferredContentMode = .mobile
        decisionHandler(.allow, preferences)
    }
    
}
