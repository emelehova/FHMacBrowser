import Foundation
import WebKit
import Cocoa

@MainActor
final class BrowserController: ObservableObject {
    @Published var urlString: String = Args.startURL
    @Published var mobileMode: Bool = Args.mobile
    @Published var liteMode: Bool = Args.lite

    let webView: WKWebView
    private let contentController = WKUserContentController()
    private let dataStore: WKWebsiteDataStore

    init() {
        self.dataStore = Args.tempProfile ? .nonPersistent() : .default()

        let config = WKWebViewConfiguration()
        // macOS: preferredContentMode доступен; ок
        config.defaultWebpagePreferences.preferredContentMode = .recommended
        config.suppressesIncrementalRendering = true
        config.preferences.javaScriptCanOpenWindowsAutomatically = false
        config.applicationNameForUserAgent = " FHMacBrowser/1.0"
        config.websiteDataStore = dataStore
        config.userContentController = contentController
        config.allowsAirPlayForMediaPlayback = false
        // macOS: НЕТ config.allowsInlineMediaPlayback — удалено
        config.mediaTypesRequiringUserActionForPlayback = [.all] // экономим автоплей

        self.webView = WKWebView(frame: .zero, configuration: config)
        self.webView.allowsLinkPreview = false

        // Инъекции скриптов по флагам
        var scripts: [WKUserScript] = []

        if Args.lite {
            let css = "var s=document.createElement('style');s.innerHTML=`\(Scripts.killAnimationsCSS)`;document.documentElement.appendChild(s);"
            scripts.append(WKUserScript(source: css, injectionTime: .atDocumentStart, forMainFrameOnly: true))
            scripts.append(WKUserScript(source: Scripts.throttleRAFJS, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        }
        if Args.lazyMedia {
            scripts.append(WKUserScript(source: Scripts.lazyMediaJS, injectionTime: .atDocumentEnd, forMainFrameOnly: false))
        }
        if let ms = Args.wsBatchMS {
            scripts.append(WKUserScript(source: Scripts.webSocketBatchJS(ms: ms), injectionTime: .atDocumentStart, forMainFrameOnly: false))
        }
        if Args.mobile {
            scripts.append(WKUserScript(source: Scripts.mobileMetaViewportJS(), injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        }
        scripts.forEach { contentController.addUserScript($0) }

        // Блокировка ресурсов
        applyBlockingRules()

        // Mobile UA при необходимости
        applyMobileUA()

        // Иногда ускоряет рендер на старых маках
        webView.setValue(false, forKey: "drawsBackground")
    }

    func bootstrap() {}

    func start() { go() }

    func go() {
        let text = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        let url = URL(string: text.hasPrefix("http") ? text : "https://\(text)") ?? URL(string:"about:blank")!
        webView.load(URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30))
    }

    func applyMobileUA() {
        if mobileMode {
            webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1"
        } else {
            webView.customUserAgent = nil
        }
    }

    func reloadWithScripts() {
        webView.reload()
    }

    private func applyBlockingRules() {
        guard !Args.blockAssets.isEmpty else { return }
        let controller = webView.configuration.userContentController
        let json = makeContentRuleListJSON()
        WKContentRuleListStore.default().compileContentRuleList(forIdentifier: "FHBlock", encodedContentRuleList: json) { list, _ in
            if let list = list {
                controller.add(list)
            }
        }
    }

    private func makeContentRuleListJSON() -> String {
        var rules: [String] = []
        if Args.blockAssets.contains("img") {
            rules.append(#"{ "trigger": { "url-filter": ".*", "resource-type": ["image"] }, "action": { "type": "block" } }"#)
        }
        if Args.blockAssets.contains("media") {
            rules.append(#"{ "trigger": { "url-filter": ".*", "resource-type": ["media"] }, "action": { "type": "block" } }"#)
        }
        if Args.blockAssets.contains("fonts") {
            rules.append(#"{ "trigger": { "url-filter": ".*", "resource-type": ["font"] }, "action": { "type": "block" } }"#)
        }
        return "[\(rules.joined(separator: ","))]"
    }
}
