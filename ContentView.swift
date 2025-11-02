import SwiftUI
import WebKit

struct ContentView: View {
    @StateObject private var controller = BrowserController()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                TextField("Введите адрес…", text: $controller.urlString, onCommit: controller.go)
                    .textFieldStyle(.roundedBorder)
                Button("Go", action: controller.go)
                Toggle("Мобайл", isOn: $controller.mobileMode)
                    .onChange(of: controller.mobileMode) { _ in controller.applyMobileUA() }
                Toggle("Lite", isOn: $controller.liteMode)
                    .onChange(of: controller.liteMode) { _ in controller.reloadWithScripts() }
            }
            .padding(8)

            WebView(webView: controller.webView)
        }
        .onAppear {
            controller.bootstrap()
            controller.start()
        }
    }
}
