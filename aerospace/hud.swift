import Cocoa

class NotchHUDWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var startY: CGFloat = 0
    var targetY: CGFloat = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        let args = CommandLine.arguments
        let text = args.count > 1 ? args[1] : "Workspace"

        guard let screen = NSScreen.main else {
            NSApplication.shared.terminate(nil)
            return
        }

        // Development に合わせた固定サイズ（ピル型）
        let fixedWidth: CGFloat = 360
        let fixedHeight: CGFloat = 82
        let pillRadius: CGFloat = fixedHeight / 2.0 // 完全なピル（カプセル）型

        // テキストラベル作成（文字サイズ40pt・中央揃え）
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 40, weight: .heavy)
        label.textColor = NSColor.white
        label.alignment = .center
        label.isBezeled = false
        label.drawsBackground = false
        label.isEditable = false
        label.isSelectable = false
        label.sizeToFit()

        let screenFrame = screen.frame
        let notchBottom: CGFloat

        // ノッチの判定と下端のY座標
        if let auxTopLeft = screen.auxiliaryTopLeftArea, auxTopLeft.height > 0 {
            notchBottom = auxTopLeft.minY
        } else {
            notchBottom = screen.visibleFrame.maxY
        }

        let centerX = screenFrame.midX - (fixedWidth / 2.0)
        self.startY = notchBottom
        self.targetY = notchBottom - fixedHeight - 8

        let initialFrame = NSRect(x: centerX, y: startY, width: fixedWidth, height: fixedHeight)
        let targetFrame = NSRect(x: centerX, y: targetY, width: fixedWidth, height: fixedHeight)

        window = NotchHUDWindow(
            contentRect: initialFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .screenSaver
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

        // ピル型背景ビュー
        let visualEffect = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: fixedWidth, height: fixedHeight))
        visualEffect.material = .popover
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = pillRadius
        visualEffect.layer?.masksToBounds = true
        visualEffect.layer?.backgroundColor = NSColor(white: 0.08, alpha: 0.92).cgColor
        visualEffect.layer?.borderColor = NSColor(white: 1.0, alpha: 0.22).cgColor
        visualEffect.layer?.borderWidth = 1.2

        // テキストをピルの中央に配置
        label.frame = NSRect(
            x: 0,
            y: (fixedHeight - label.frame.height) / 2.0,
            width: fixedWidth,
            height: label.frame.height
        )
        visualEffect.addSubview(label)
        window.contentView = visualEffect

        window.alphaValue = 0.0
        window.orderFrontRegardless()

        // ニョキッと生えてくるスプリングアニメーション
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.28
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 1.25, 0.4, 1.0)
            self.window.animator().setFrame(targetFrame, display: true)
            self.window.animator().alphaValue = 1.0
        }, completionHandler: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.22
                    context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                    self.window.animator().setFrame(initialFrame, display: true)
                    self.window.animator().alphaValue = 0.0
                }, completionHandler: {
                    NSApplication.shared.terminate(nil)
                })
            }
        })
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
