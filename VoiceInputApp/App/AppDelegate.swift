import SwiftUI
import AppKit
import Speech
import AVFoundation

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var mainViewModel: MainViewModel?
    private var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 App launching...")

        // Request all permissions first
        requestAllPermissions()

        // Setup status bar item
        setupStatusBarItem()

        // Setup main view model
        mainViewModel = MainViewModel()
        mainViewModel?.setupServices()

        // Setup popover
        setupPopover()

        // Setup event monitor to close popover when clicking outside
        setupEventMonitor()

        // Check accessibility permission
        checkAccessibilityPermission()
    }

    private func requestAllPermissions() {
        print("📝 Requesting permissions...")

        // 1. Request Microphone permission
        requestMicrophonePermission()

        // 2. Request Speech Recognition permission
        requestSpeechRecognitionPermission()
    }

    private func requestMicrophonePermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)

        print("🎤 Microphone status: \(status.rawValue)")

        switch status {
        case .notDetermined:
            // Request permission
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    if granted {
                        print("✅ Microphone permission granted")
                    } else {
                        print("❌ Microphone permission denied")
                        self.showPermissionAlert(
                            title: "需要麦克风权限",
                            message: "请在系统设置 > 隐私与安全性 > 麦克风中允许此应用。"
                        )
                    }
                }
            }
        case .denied, .restricted:
            print("⚠️ Microphone permission denied or restricted")
            showPermissionAlert(
                title: "需要麦克风权限",
                message: "请在系统设置 > 隐私与安全性 > 麦克风中允许此应用。"
            )
        case .authorized:
            print("✅ Microphone already authorized")
        @unknown default:
            print("⚠️ Unknown microphone status")
        }
    }

    private func requestSpeechRecognitionPermission() {
        let status = SFSpeechRecognizer.authorizationStatus()

        print("🗣️ Speech recognition status: \(status.rawValue)")

        switch status {
        case .notDetermined:
            SFSpeechRecognizer.requestAuthorization { status in
                DispatchQueue.main.async {
                    if status == .authorized {
                        print("✅ Speech recognition permission granted")
                    } else {
                        print("❌ Speech recognition permission denied")
                        self.showPermissionAlert(
                            title: "需要语音识别权限",
                            message: "请在系统设置 > 隐私与安全性 > 语音识别中允许此应用。"
                        )
                    }
                }
            }
        case .denied, .restricted:
            print("⚠️ Speech recognition permission denied or restricted")
            showPermissionAlert(
                title: "需要语音识别权限",
                message: "请在系统设置 > 隐私与安全性 > 语音识别中允许此应用。"
            )
        case .authorized:
            print("✅ Speech recognition already authorized")
        @unknown default:
            print("⚠️ Unknown speech recognition status")
        }
    }

    private func checkAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)

        print("⌨️ Accessibility trusted: \(trusted)")

        if !trusted {
            // Show alert explaining how to enable accessibility
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let alert = NSAlert()
                alert.messageText = "需要辅助功能权限"
                alert.informativeText = """
                为了模拟键盘输入，需要授予辅助功能权限：

                1. 打开"系统设置"
                2. 进入"隐私与安全性" > "辅助功能"
                3. 点击左下角锁图标解锁
                4. 将 VoiceInputApp 添加到列表并勾选

                如果列表中没有此应用，请手动添加应用程序。
                """
                alert.alertStyle = .warning
                alert.addButton(withTitle: "打开系统设置")
                alert.addButton(withTitle: "稍后设置")

                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    // Open System Preferences to Accessibility
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                        NSWorkspace.shared.open(url)
                    }
                }

                // Request accessibility permission with prompt
                let promptOptions = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
                _ = AXIsProcessTrustedWithOptions(promptOptions as CFDictionary)
            }
        }
    }

    private func showPermissionAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "打开系统设置")
        alert.addButton(withTitle: "稍后设置")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    private func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "Voice Input")
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        }
    }

    @objc private func statusBarButtonClicked() {
        if popover?.isShown == true {
            popover?.close()
        } else if let button = statusItem?.button {
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func setupPopover() {
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 220)
        popover.behavior = .transient
        if let viewModel = mainViewModel {
            popover.contentViewController = NSHostingController(rootView: MainView(viewModel: viewModel))
        }
        popover.delegate = self
        self.popover = popover
    }

    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if self?.popover?.isShown == true {
                self?.popover?.close()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        mainViewModel?.cleanup()
    }
}

// MARK: - NSPopoverDelegate
extension AppDelegate: NSPopoverDelegate {
    func popoverWillClose(_ notification: Notification) {
        // Popover will close
    }
}