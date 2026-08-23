import AppKit
import Foundation
import UniformTypeIdentifiers

struct AppIdentity: Identifiable {
    let bundleID: String
    let name: String
    let icon: NSImage

    var id: String { bundleID }
}

enum AppBundleResolver {
    static func identity(for bundleID: String) -> AppIdentity {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            let name = displayName(for: url, bundleID: bundleID)
            let icon = NSWorkspace.shared.icon(forFile: url.path)
            return AppIdentity(bundleID: bundleID, name: name, icon: icon)
        }

        let fallbackName = friendlyFallbackName(for: bundleID)
        return AppIdentity(
            bundleID: bundleID,
            name: fallbackName,
            icon: NSWorkspace.shared.icon(for: .applicationBundle)
        )
    }

    static func bundleID(for appURL: URL) -> String? {
        Bundle(url: appURL)?.bundleIdentifier
    }

    private static func displayName(for appURL: URL, bundleID: String) -> String {
        if let bundle = Bundle(url: appURL) {
            if let displayName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String,
               !displayName.isEmpty {
                return displayName
            }
            if let bundleName = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String,
               !bundleName.isEmpty {
                return bundleName
            }
        }

        let fileName = FileManager.default.displayName(atPath: appURL.path)
        if !fileName.isEmpty, fileName != appURL.lastPathComponent {
            return fileName
        }

        return friendlyFallbackName(for: bundleID)
    }

    private static func friendlyFallbackName(for bundleID: String) -> String {
        let knownNames: [String: String] = [
            "com.1password.1password": "1Password",
            "com.agilebits.onepassword7": "1Password 7",
            "com.apple.Safari": "Safari",
            "com.apple.keychainaccess": "钥匙串访问",
        ]

        if let known = knownNames[bundleID] {
            return known
        }

        if let last = bundleID.split(separator: ".").last {
            return String(last)
        }

        return bundleID
    }
}

enum AppPicker {
    @MainActor
    static func pickApplication() -> String? {
        let panel = NSOpenPanel()
        panel.title = "选择要排除的应用"
        panel.message = "选择应用后，将忽略其复制内容"
        panel.prompt = "添加"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.application]
        if FileManager.default.fileExists(atPath: "/Applications") {
            panel.directoryURL = URL(fileURLWithPath: "/Applications")
        }

        guard panel.runModal() == .OK, let url = panel.url else {
            return nil
        }

        return AppBundleResolver.bundleID(for: url)
    }
}
