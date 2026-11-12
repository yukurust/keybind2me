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

        // アプリ起動・終了時、または1.5秒ごとにDockの形状を完全実測して動的追従
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

        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.updateLayout()
        }
    }

    func setupWindow() {
        let initialWidth: CGFloat = 380
        let initialHeight: CGFloat = 80
        let initialBottomMargin: CGFloat = 6

        window = CheatSheetWindow(
            contentRect: NSRect(x: 0, y: initialBottomMargin, width: initialWidth, height: initialHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .screenSaver
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

        // Dockと完全に同一のプライベートマテリアル (Dockマテリアル rawValue: 20)
        visualEffect = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: initialWidth, height: initialHeight))
        // rawValue 20 = macOS内部の kCGSWindowBackdropMaterialDock (Dock専用ブラー)
        visualEffect.material = NSVisualEffectView.Material(rawValue: 20) ?? .fullScreenUI
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        let cornerRadius: CGFloat = 28
        visualEffect.layer?.cornerRadius = cornerRadius
        visualEffect.layer?.cornerCurve = .continuous
        visualEffect.layer?.masksToBounds = true

        stack = NSStackView(frame: NSRect(x: 14, y: 4, width: initialWidth - 28, height: initialHeight - 8))
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

    struct DockGeometry {
        let x: CGFloat
        let yFromBottom: CGFloat
        let height: CGFloat
    }

    func getExactDockGeometry() -> DockGeometry? {
        guard let screen = NSScreen.main else { return nil }
        let apps = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock")
        guard let dockApp = apps.first else { return nil }
        let axApp = AXUIElementCreateApplication(dockApp.processIdentifier)
        var value: AnyObject?
        if AXUIElementCopyAttributeValue(axApp, kAXChildrenAttribute as CFString, &value) == .success,
           let children = value as? [AXUIElement] {
            for child in children {
                var posVal: AnyObject?, sizeVal: AnyObject?
                if AXUIElementCopyAttributeValue(child, kAXPositionAttribute as CFString, &posVal) == .success,
                   AXUIElementCopyAttributeValue(child, kAXSizeAttribute as CFString, &sizeVal) == .success,
                   let p = posVal, let s = sizeVal {
                    var pos = CGPoint.zero, size = CGSize.zero
                    if AXValueGetValue(p as! AXValue, .cgPoint, &pos),
                       AXValueGetValue(s as! AXValue, .cgSize, &size),
                       pos.x > 0 && size.height > 20 {
                        let yFromBottom = screen.frame.height - (pos.y + size.height)
                        return DockGeometry(x: pos.x, yFromBottom: yFromBottom, height: size.height)
                    }
                }
            }
        }
        return nil
    }

    func updateLayout() {
        guard let screen = NSScreen.main else { return }

        // ウィンドウやアプリの作業領域の下端（Dockの上限ライン = visibleFrame.minY）
        // 上部に1pxの隙間をあけるため - 1.0
        let maxAllowedTop = screen.visibleFrame.minY - 1.0

        let targetWidth: CGFloat
        var targetHeight: CGFloat
        var bottomMargin: CGFloat

        if let geo = getExactDockGeometry() {
            targetWidth = max(geo.x, 260)
            targetHeight = geo.height
            // bottomのgapを1px小さくする (geo.yFromBottom - 1.0)
            bottomMargin = max(geo.yFromBottom - 1.0, 0)

            // 上端が maxAllowedTop (visibleFrame.minY - 1px) を超えないよう調整
            let currentTop = bottomMargin + targetHeight
            if currentTop > maxAllowedTop {
                bottomMargin = maxAllowedTop - targetHeight
            }
        } else {
            targetWidth = 380
            targetHeight = max(maxAllowedTop - 5, 60)
            bottomMargin = 5
        }

        let leftMargin: CGFloat = 0
        let newFrame = NSRect(x: leftMargin, y: bottomMargin, width: targetWidth, height: targetHeight)

        if window.frame != newFrame {
            window.setFrame(newFrame, display: true, animate: true)
            visualEffect.frame = NSRect(x: 0, y: 0, width: targetWidth, height: targetHeight)
            let cornerRadius: CGFloat = 28
            visualEffect.layer?.cornerRadius = cornerRadius
            visualEffect.layer?.cornerCurve = .continuous
            stack.frame = NSRect(x: 14, y: 4, width: targetWidth - 28, height: targetHeight - 8)
        }
    }

    func makeSectionView(title: String, titleColor: NSColor, items: [(String, String)]) -> NSView {
        let container = NSStackView()
        container.orientation = .vertical
        container.alignment = .leading
        container.spacing = 1.2

        let header = NSTextField(labelWithString: title)
        header.font = NSFont.systemFont(ofSize: 10.5, weight: .bold)
        header.textColor = titleColor
        header.isBezeled = false
        header.drawsBackground = false
        container.addArrangedSubview(header)

        for (key, desc) in items {
            let row = NSStackView()
            row.orientation = .horizontal
            row.spacing = 6

            let keyLabel = NSTextField(labelWithString: key)
            keyLabel.font = NSFont.monospacedSystemFont(ofSize: 9.5, weight: .bold)
            keyLabel.textColor = NSColor.white
            keyLabel.isBezeled = false
            keyLabel.drawsBackground = false

            let descLabel = NSTextField(labelWithString: desc)
            descLabel.font = NSFont.systemFont(ofSize: 9.5, weight: .regular)
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
