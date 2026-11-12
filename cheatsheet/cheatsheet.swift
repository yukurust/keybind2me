import Cocoa

class CheatSheetWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: CheatSheetWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let screen = NSScreen.main else { return }

        let screenWidth = screen.frame.width // 2704pt
        let dockAreaHeight = screen.visibleFrame.minY > 0 ? screen.visibleFrame.minY : 93.0
        let bottomMargin: CGFloat = 8
        let height: CGFloat = dockAreaHeight - 12 // 81pt
        let cornerRadius: CGFloat = 22

        // 画面左端からDockの左端までのスペースを埋める
        // 画面左マージン: 14pt (Dockの右端・下端の浮きと合わせる)
        let leftMargin: CGFloat = 14

        // Dock左端までの距離 (引数で幅の上書きが可能: デフォルト 660pt)
        let args = CommandLine.arguments
        var targetWidth: CGFloat = 660
        if args.count > 1, let w = Double(args[1]) {
            targetWidth = CGFloat(w)
        }

        let width = targetWidth
        let x: CGFloat = leftMargin
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
        window.level = .screenSaver
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
        visualEffect.layer?.backgroundColor = NSColor(white: 0.11, alpha: 0.88).cgColor
        visualEffect.layer?.borderColor = NSColor(white: 1.0, alpha: 0.22).cgColor
        visualEffect.layer?.borderWidth = 1.0

        // 横幅が広がったため、ゆったり左右に2セクション均等配置
        let stack = NSStackView(frame: NSRect(x: 24, y: 6, width: width - 48, height: height - 12))
        stack.orientation = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 28

        // 1. AeroSpace セクション
        let aeroView = makeSectionView(
            title: "⌥ AeroSpace (Workspace & Tiling)",
            titleColor: NSColor(red: 0.35, green: 0.78, blue: 0.98, alpha: 1.0),
            items: [
                ("D/B/N/C/1", "WS移動 (Dev / Brow / Note / Chat / 1)"),
                ("⇧+D/B..", "ウィンドウを該当WSへ送る"),
                ("H / J / K / L", "ウィンドウフォーカス移動 (Vim)"),
                ("F / M", "フローティング切替 / フルスクリーン")
            ]
        )

        // 2. WezTerm セクション (Leader: Ctrl+Q)
        let wezView = makeSectionView(
            title: "⌃Q WezTerm (Terminal & Pane)",
            titleColor: NSColor(red: 0.60, green: 0.90, blue: 0.45, alpha: 1.0),
            items: [
                ("v / s", "ペインを縦分割 / 横分割"),
                ("h / j / k / l", "ペイン間のフォーカス移動"),
                ("z", "ペイン最大化・ズーム切替"),
                ("w / c", "ワークスペース選択 / 新規タブ")
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
            row.spacing = 8

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
