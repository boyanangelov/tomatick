import AppKit

/// Monochrome template image for the status bar: recent trees, the growing sapling, and the timer.
enum MenuBarIcon {
    static let height: CGFloat = 18
    static let maxTrees = 5
    private static let treeWidth: CGFloat = 8
    private static let gap: CGFloat = 2
    private static let ground: CGFloat = 3

    static func image(forest: [Int], phase: Phase, state: RunState, growth: Double?, time: String) -> NSImage {
        let trees = Array(forest.suffix(maxTrees))
        let font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        let text = state == .idle ? nil
            : NSAttributedString(string: time, attributes: [.font: font, .foregroundColor: NSColor.black])

        var width = CGFloat(trees.count) * (treeWidth + gap)
        width += treeWidth + 2                    // sapling / cup slot
        if let text { width += 4 + ceil(text.size().width) }

        let img = NSImage(size: NSSize(width: width, height: height), flipped: false) { _ in
            NSColor.black.setFill()
            NSColor.black.setStroke()
            var x: CGFloat = 0
            for seed in trees {
                drawTree(kind: plantKind(seed: seed), x: x, scale: 1)
                x += treeWidth + gap
            }
            if phase == .work {
                // Sapling grows with the session; a small sprout when not started.
                let g = state == .idle ? 0 : (growth ?? 0)
                drawTree(kind: 0, x: x, scale: state == .idle ? 0.6 : 0.3 + 0.7 * g)
            } else if let cup = NSImage(systemSymbolName: "cup.and.saucer.fill", accessibilityDescription: "Break") {
                cup.draw(in: NSRect(x: x - 1, y: 3, width: treeWidth + 3, height: 11))
            }
            x += treeWidth + 2
            if let text {
                let h = text.size().height
                text.draw(at: NSPoint(x: x + 4, y: (height - h) / 2))
            }
            return true
        }
        img.isTemplate = true
        return img
    }

    /// Draws a ~8pt wide, ~14pt tall silhouette sitting on the ground line; `scale` shrinks toward the ground.
    private static func drawTree(kind: Int, x: CGFloat, scale s: CGFloat) {
        let cx = x + treeWidth / 2
        let b = ground
        switch kind {
        case 0: // pine
            NSRect(x: cx - 0.75 * s, y: b, width: 1.5 * s, height: 2.5 * s).fill()
            for i in 0..<3 {
                let w = (8 - 1.8 * CGFloat(i)) * s
                let base = b + 2 * s + CGFloat(i) * 3 * s
                let p = NSBezierPath()
                p.move(to: NSPoint(x: cx - w / 2, y: base))
                p.line(to: NSPoint(x: cx + w / 2, y: base))
                p.line(to: NSPoint(x: cx, y: base + 5.5 * s))
                p.close(); p.fill()
            }
        case 1: // round tree
            NSRect(x: cx - 0.8 * s, y: b, width: 1.6 * s, height: 5 * s).fill()
            NSBezierPath(ovalIn: NSRect(x: cx - 4 * s, y: b + 4 * s, width: 8 * s, height: 8.5 * s)).fill()
        case 2: // bush
            NSBezierPath(ovalIn: NSRect(x: cx - 4 * s, y: b, width: 5 * s, height: 5 * s)).fill()
            NSBezierPath(ovalIn: NSRect(x: cx - 1 * s, y: b, width: 5 * s, height: 5 * s)).fill()
            NSBezierPath(ovalIn: NSRect(x: cx - 3 * s, y: b + 2 * s, width: 6 * s, height: 6 * s)).fill()
        default: // flower
            let stem = NSBezierPath()
            stem.move(to: NSPoint(x: cx, y: b)); stem.line(to: NSPoint(x: cx, y: b + 8 * s))
            stem.lineWidth = 1.2 * s; stem.stroke()
            let r = 3 * s
            NSBezierPath(ovalIn: NSRect(x: cx - r, y: b + 8 * s - r * 0.6, width: 2 * r, height: 2 * r)).fill()
        }
        NSRect(x: x - gap / 2, y: b - 1, width: treeWidth + gap, height: 0.75).fill()   // ground line
    }
}
