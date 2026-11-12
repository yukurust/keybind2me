import Cocoa

class CheatSheetWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: CheatSheetWindow!
    var visualEffect: NSVisualEffectView!
    var stack: NSStackView!
    var updateTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupWindow()
        updateLayout()

        // アプリ起動・終了時、または2秒ごとにDockの幅を完全実測して動的に追従
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleAppChange),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleAppChange),
            name: NSWorkspace.didTerminateApplicationNotification,
            object: nil
        )

        updateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateLayout()
        }
    }

    func setupWindow() {
        let height: CGFloat = 87
        let bottomMargin: CGFloat = 5
        let cornerRadius: CGFloat = 24
        let initialWidth: CGFloat = 380
        let leftMargin: CGFloat = 0

        window = CheatSheetWindow(
            contentRect: NSRect(x: leftMargin, y: bottomMargin, width: initialWidth, height: height),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .screenSaver
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

        visualEffect = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: initialWidth, height: height))
        visualEffect.material = .hudWindow
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = cornerRadius
        visualEffect.layer?.masksToBounds = true
        visualEffect.layer?.backgroundColor = NSColor(white: 0.11, alpha: 0.88).cgColor
        visualEffect.layer?.borderColor = NSColor(white: 1.0, alpha: 0.22).cgColor
        visualEffect.layer?.borderWidth = 1.0

        stack = NSStackView(frame: NSRect(x: 14, y: 7, width: initialWidth - 28, height: height - 14))
        stack.orientation = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 16

        let aeroView = makeSectionView(
            title: "⌥ AeroSpace",
            titleColor: NSColor(red: 0.35, green: 0.78, blue: 0.98, alpha: 1.0),
            items: [
                ("D/B/N/C/1", "WS移動"),
                ("⇧+D/B..", "該当WSへ送る"),
                ("H/J/K/L", "フォーカス移動"),
                ("F / M", "Float / Full")
            ]
        )

        let wezView = makeSectionView(
            title: "⌃Q WezTerm",
            titleColor: NSColor(red: 0.60, green: 0.90, blue: 0.45, alpha: 1.0),
            items: [
                ("v / s", "縦/横分割"),
                ("h/j/k/l", "ペイン移動"),
                ("z", "ペイン最大化"),
                ("w / c", "WS選択 / 新規タブ")
            ]
        )

        stack.addArrangedSubview(aeroView)
        stack.addArrangedSubview(wezView)
        visualEffect.addSubview(stack)
        window.contentView = visualEffect
        window.orderFrontRegardless()
    }

    @objc func handleAppChange() {
        DispatchQueue.main.async { [weak self] in
            self?.updateLayout()
        }
    }

    // macOS Accessibility APIからDockの正確な左端X座標を1ピクセル単位で取得
    func getExactDockLeft() -> CGFloat? {
        let apps = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock")
        guard let dockApp = apps.first else { return nil }
        let axApp = AXUIElementCreateApplication(dockApp.processIdentifier)
        var value: AnyObject?
        if AXUIElementCopyAttributeValue(axApp, kAXChildrenAttribute as CFString, &value) == .success,
           let children = value as? [AXUIElement] {
            for child in children {
                var posVal: AnyObject?
                if AXUIElementCopyAttributeValue(child, kAXPositionAttribute as CFString, &posVal) == .success,
                   let p = posVal {
                    var pos = CGPoint.zero
                    if AXValueGetValue(p as! AXValue, .cgPoint, &pos), pos.x > 0 {
                        return pos.x
                    }
                }
            }
        }
        return nil
    }

    func calculateAvailableWidth() -> CGFloat {
        // Accessibility APIでDockの正確な左端X座標を取得
        if let dockLeft = getExactDockLeft() {
            // 左マージン0ptからDock左端までピッタリ埋める
            // 隙間を2pxに詰める（8px - 6px = 2px）
            let gapToDock: CGFloat = 2.0
            return max(dockLeft - gapToDock, 280)
        }

        // フォールバック（計算による推定）
        guard let screen = NSScreen.main else { return 380 }
        let screenWidth = screen.frame.width
        let defaults = UserDefaults(suiteName: "com.apple.dock")
        let tilesize = CGFloat(defaults?.integer(forKey: "tilesize") ?? 67)
        let persistentApps = defaults?.array(forKey: "persistent-apps") as? [[String: Any]] ?? []
        let runningApps = NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }
        let total = CGFloat(persistentApps.count + runningApps.count + 2)
        let estWidth = (total * tilesize) + (total * 10) + 40
        let dockLeft = (screenWidth - estWidth) / 2.0
        return max(dockLeft - 8.0, 280)
    }

    func updateLayout() {
        let targetWidth = calculateAvailableWidth()
        let height: CGFloat = 87
        let bottomMargin: CGFloat = 5
        let leftMargin: CGFloat = 0

        let newFrame = NSRect(x: leftMargin, y: bottomMargin, width: targetWidth, height: height)

        if window.frame != newFrame {
            window.setFrame(newFrame, display: true, animate: true)
            visualEffect.frame = NSRect(x: 0, y: 0, width: targetWidth, height: height)
            stack.frame = NSRect(x: 14, y: 7, width: targetWidth - 28, height: height - 14)
        }
    }

    func makeSectionView(title: String, titleColor: NSColor, items: [(String, String)]) -> NSView {
        let container = NSStackView()
        container.orientation = .vertical
        container.alignment = .leading
        container.spacing = 1.5

        let header = NSTextField(labelWithString: title)
        header.font = NSFont.systemFont(ofSize: 11, weight: .bold)
        header.textColor = titleColor
        header.isBezeled = false
        header.drawsBackground = false
        container.addArrangedSubview(header)

        for (key, desc) in items {
            let row = NSStackView()
            row.orientation = .horizontal
            row.spacing = 6

            let keyLabel = NSTextField(labelWithString: key)
            keyLabel.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .bold)
            keyLabel.textColor = NSColor.white
            keyLabel.isBezeled = false
            keyLabel.drawsBackground = false

            let descLabel = NSTextField(labelWithString: desc)
            descLabel.font = NSFont.systemFont(ofSize: 10, weight: .regular)
            descLabel.textColor = NSColor(white: 0.85, alpha: 1.0)
            descLabel.isBezeled = false
            descLabel.drawsBackground = false

            row.addArrangedSubview(keyLabel)
            row.addArrangedSubview(descLabel)
            container.addArrangedSubview(row)
        }

        return container
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
