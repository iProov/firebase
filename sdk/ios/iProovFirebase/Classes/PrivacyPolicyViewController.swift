//
//  PrivacyPolicyViewController.swift
//  iProovFirebase
//
//  Created by Jonathan Ellis on 28/08/2024.
//

import Foundation
import WebKit

class PrivacyPolicyViewController: UIViewController {

    private let url: URL
    private let callback: (Bool) -> Void

    private let webView = WKWebView()

    init(url: URL, callback: @escaping (Bool) -> Void) {
        self.url = url
        self.callback = callback
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        webView.load(URLRequest(url: url))
    }

    func presentModally() {
        let topViewController = UIApplication.shared.windows.filter(\.isKeyWindow).first?.topViewController
        topViewController?.present(self, animated: true)
    }

}

extension PrivacyPolicyViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        guard let url = navigationAction.request.url, url.scheme == "sdk" else  {
            decisionHandler(.allow)
            return
        }

        let result = url.lastPathComponent

        self.dismiss(animated: true) {
            self.callback(result == "accept")
        }

        decisionHandler(.cancel)
    }

}

private extension UIWindow {
    var topViewController: UIViewController? {
        var topController = rootViewController

        // Find the top-most view controller
        while let presentedViewController = topController?.presentedViewController {
            topController = presentedViewController
        }

        return topController
    }
}
