import SwiftUI
import Cocoa
import Darwin

@main
struct FHMacBrowserApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 900, minHeight: 600)
                .onAppear { appDelegate.applyKioskIfNeeded() }
        }
        .windowStyle(.titleBar)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var lockFile: FileHandle?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Single-instance lock через файл в /tmp
        let path = "/tmp/fhmacbrowser.lock"
        if !FileManager.default.fileExists(atPath: path) {
            FileManager.default.createFile(atPath: path, contents: nil)
        }
        lockFile = FileHandle(forUpdatingAtPath: path)

        if let fd = lockFile?.fileDescriptor {
            if flock(fd, LOCK_EX | LOCK_NB) != 0 {
                NSApp.terminate(nil) // Уже запущено
            }
        }

        if Args.keepAwake { Power.keepAwakeOn() }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if Args.keepAwake { Power.keepAwakeOff() }
        if let fd = lockFile?.fileDescriptor { flock(fd, LOCK_UN) }
    }

    func applyKioskIfNeeded() {
        guard Args.kiosk else { return }
        if let window = NSApp.windows.first {
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.styleMask.insert(.fullSizeContentView)
            window.toggleFullScreen(nil)
        }
    }
}

enum Args {
    static let raw = ProcessInfo.processInfo.arguments

    static func has(_ flag: String) -> Bool { raw.contains(flag) }

    static var startURL: String {
        if let arg = raw.first(where: { $0.hasPrefix("--start=") }) {
            return String(arg.dropFirst("--start=".count))
        }
        return "about:blank"
    }

    static var blockAssets: Set<String> {
        guard let a = raw.first(where: { $0.hasPrefix("--block-assets=") }) else { return [] }
        let list = String(a.dropFirst("--block-assets=".count))
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        return Set(list)
    }

    static var wsBatchMS: Int? {
        guard let a = raw.first(where: { $0.hasPrefix("--ws-batch=") }) else { return nil }
        return Int(a.split(separator: "=").last ?? "")
    }

    static var lite: Bool { has("--lite") }
    static var lazyMedia: Bool { has("--lazy-media") }
    static var mobile: Bool { has("--mobile") }
    static var kiosk: Bool { has("--kiosk") }
    static var tempProfile: Bool { has("--temp-profile") }
    static var keepAwake: Bool { has("--keep-awake") }
}
