import UIKit
import WebKit

class PrivacyPolicyViewController: UIViewController, WKNavigationDelegate {
    
    @IBOutlet weak var webView: WKWebView!
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        setupActivityIndicator()
        loadPrivacyPolicy()
    }
    
    private func setupWebView() {
        // Configure the IB-connected web view
        webView.navigationDelegate = self
    }
    
    private func setupActivityIndicator() {
        // Configure activity indicator
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = UIColor(rgb: 0x662CAA) // Use app's theme color
        
        // Add to view hierarchy
        view.addSubview(activityIndicator)
        
        // Center in view
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func loadPrivacyPolicy() {
        // Start loading indicator
        activityIndicator.startAnimating()
        
        // Load privacy policy from a URL
        if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
            let request = URLRequest(url: url)
            webView.load(request)
        } else {
            
            // Fallback to local HTML if URL is not available
            if let htmlPath = Bundle.main.path(forResource: "privacy-policy", ofType: "html") {
                let url = URL(fileURLWithPath: htmlPath)
                webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
            } else {
                // Show error if neither URL nor local file is available
                showError()
            }
        }
    }
    
    private func showError() {
        let alert = UIAlertController(
            title: "Error",
            message: "Unable to load privacy policy. Please try again later.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
        showError()
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
        showError()
    }
} 
