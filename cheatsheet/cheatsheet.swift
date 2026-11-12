import Cocoa

class CheatSheetWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: CheatSheetWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let screen = NSScreen.main else { return }

        // Dockが占有している正確な高さを取得
        // screen.visibleFrame.minY はDockの下端から上端までの総占有高さ (現在 93pt)
        let dockAreaHeight = screen.visibleFrame.minY > 0 ? screen.visibleFrame.minY : 93.0

        // macOS Dockの実際の形状設計:
        // 画面下端から浮いているマージン: 約 8pt
        // 上端の余白マージン: 約 4pt
        // したがってDockカプセルの実高さ = dockAreaHeight - 12pt (93 - 12 = 81pt)
        let bottomMargin: CGFloat = 8
        let height: CGFloat = dockAreaHeight - 12
        let width: CGFloat = 490
        let cornerRadius: CGFloat = 22

        let x: CGFloat = 14
        let y: CGFloat = bottomMargin

        let windowRect = NSRect(x: x, y: y, width: width, height: height)

        window = CheatSheetWindow(
            contentRect: windowRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = .clear

        // Dock (level 20) の直下レイヤー (level 19)
        let dockLevel = Int(CGWindowLevelForKey(.dockWindow))
        window.level = NSWindow.Level(rawValue: dockLevel - 1)

        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

        // Dockと完全に一致させた透過すりガラス背景
        let visualEffect = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        visualEffect.material = .hudWindow
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = cornerRadius
        visualEffect.layer?.masksToBounds = true
        visualEffect.layer?.backgroundColor = NSColor(white: 0.11, alpha: 0.85).cgColor
        visualEffect.layer?.borderColor = NSColor(white: 1.0, alpha: 0.22).cgColor
        visualEffect.layer?.borderWidth = 1.0

        // コンテンツ用のStackView（上下中央配置）
        let stack = NSStackView(frame: NSRect(x: 18, y: 8, width: width - 36, height: height - 16))
        stack.orientation = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 18

        // 1. AeroSpace セクション
        let aeroView = makeSectionView(
            title: "⌥ AeroSpace",
            titleColor: NSColor(red: 0.35, green: 0.78, blue: 0.98, alpha: 1.0),
            items: [
                ("D/B/N/C/1", "WS移動"),
                ("⇧+D/B..", "送る"),
                ("H/J/K/L", "フォーカス"),
                ("F / M", "Float / Full")
            ]
        )

        // 2. WezTerm セクション (Leader: Ctrl+Q)
        let wezView = makeSectionView(
            title: "⌃Q WezTerm",
            titleColor: NSColor(red: 0.60, green: 0.90, blue: 0.45, alpha: 1.0),
            items: [
                ("v / s", "縦/横分割"),
                ("h/j/k/l", "ペイン移動"),
                ("z", "最大化"),
                ("w / c", "WS / タブ")
            ]
        )

        stack.addArrangedSubview(aeroView)
        stack.addArrangedSubview(wezView)

        visualEffect.addSubview(stack)
        window.contentView = visualEffect

        window.alphaValue = 1.0
        window.orderFrontRegardless()
    }

    func makeSectionView(title: String, titleColor: NSColor, items: [(String, String)]) -> NSView {
        let container = NSStackView()
        container.orientation = .vertical
        container.alignment = .leading
        container.spacing = 2

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
            descLabel.textColor = NSColor(white: 0.84, alpha: 1.0)
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
