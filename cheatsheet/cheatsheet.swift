import Cocoa

class CheatSheetWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: CheatSheetWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let screen = NSScreen.main else { return }

        // Dockと同じ高さ・すりガラス感
        let dockHeight: CGFloat = screen.visibleFrame.minY > 0 ? screen.visibleFrame.minY - 14 : 76
        let height: CGFloat = max(dockHeight, 72)
        let width: CGFloat = 460
        let cornerRadius: CGFloat = 20

        // 画面左下（Dockと同じY位置・左余白14pt）
        let x: CGFloat = 16
        let y: CGFloat = 8

        let windowRect = NSRect(x: x, y: y, width: width, height: height)

        window = CheatSheetWindow(
            contentRect: windowRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.ignoresMouseEvents = true // 操作の邪魔にならないようクリック透過
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

        // Dock風のすりガラス背景
        let visualEffect = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        visualEffect.material = .hudWindow
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = cornerRadius
        visualEffect.layer?.masksToBounds = true
        visualEffect.layer?.backgroundColor = NSColor(white: 0.12, alpha: 0.78).cgColor
        visualEffect.layer?.borderColor = NSColor(white: 1.0, alpha: 0.20).cgColor
        visualEffect.layer?.borderWidth = 1.0

        // コンテンツ用のStackView
        let stack = NSStackView(frame: NSRect(x: 16, y: 8, width: width - 32, height: height - 16))
        stack.orientation = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 16

        // 1. AeroSpace セクション
        let aeroView = makeSectionView(
            title: "⌥ AeroSpace",
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
        window.orderFrontRegardless()
    }

    func makeSectionView(title: String, items: [(String, String)]) -> NSView {
        let container = NSStackView()
        container.orientation = .vertical
        container.alignment = .leading
        container.spacing = 2

        let header = NSTextField(labelWithString: title)
        header.font = NSFont.systemFont(ofSize: 11, weight: .bold)
        header.textColor = NSColor(red: 0.45, green: 0.82, blue: 1.0, alpha: 1.0)
        container.addArrangedSubview(header)

        for (key, desc) in items {
            let row = NSStackView()
            row.orientation = .horizontal
            row.spacing = 6

            let keyLabel = NSTextField(labelWithString: key)
            keyLabel.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .semibold)
            keyLabel.textColor = NSColor.white

            let descLabel = NSTextField(labelWithString: desc)
            descLabel.font = NSFont.systemFont(ofSize: 10, weight: .regular)
            descLabel.textColor = NSColor(white: 0.82, alpha: 1.0)

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
