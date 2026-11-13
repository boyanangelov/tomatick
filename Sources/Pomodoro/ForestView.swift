import SwiftUI

/// Small deterministic RNG so layout and tree looks are stable across redraws.
struct SplitMix {
    var state: UInt64
    init(_ seed: Int) { state = UInt64(truncatingIfNeeded: seed) &+ 0x9E37_79B9_7F4A_7C15 }
    mutating func next() -> Double {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        z ^= z >> 31
        return Double(z >> 11) / Double(1 << 53)
    }
}

struct ForestView: View {
    let trees: [Int]
    let growth: Double?   // nil during breaks

    private static let columns = 8
    private static let rows = 3
    private static let capacity = columns * rows

    /// Slot positions in unit space (x, row), shuffled with a fixed seed so the forest fills in evenly.
    private static let slots: [(x: Double, row: Int)] = {
        var rng = SplitMix(42)
        var s: [(Double, Int)] = []
        for r in 0..<rows {
            for c in 0..<columns {
                let jitter = (rng.next() - 0.5) * 0.6
                let offset = r % 2 == 0 ? 0.0 : 0.5
                s.append(((Double(c) + 0.5 + offset * 0.5 + jitter) / Double(columns), r))
            }
        }
        // Fisher–Yates with fixed RNG
        for i in stride(from: s.count - 1, to: 0, by: -1) {
            let j = Int(rng.next() * Double(i + 1))
            s.swapAt(i, j)
        }
        return s
    }()

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height

            // Sky
            ctx.fill(Path(CGRect(origin: .zero, size: size)),
                     with: .linearGradient(Gradient(colors: [Color(red: 0.62, green: 0.82, blue: 0.95),
                                                             Color(red: 0.86, green: 0.94, blue: 0.97)]),
                                           startPoint: .zero, endPoint: CGPoint(x: 0, y: h)))
            // Hills / ground
            var hill = Path()
            hill.move(to: CGPoint(x: 0, y: h * 0.5))
            hill.addCurve(to: CGPoint(x: w, y: h * 0.45),
                          control1: CGPoint(x: w * 0.3, y: h * 0.35),
                          control2: CGPoint(x: w * 0.7, y: h * 0.58))
            hill.addLine(to: CGPoint(x: w, y: h)); hill.addLine(to: CGPoint(x: 0, y: h)); hill.closeSubpath()
            ctx.fill(hill, with: .color(Color(red: 0.55, green: 0.75, blue: 0.4)))
            ctx.fill(Path(CGRect(x: 0, y: h * 0.62, width: w, height: h * 0.38)),
                     with: .color(Color(red: 0.45, green: 0.68, blue: 0.33)))

            // Collect drawables, sort back-to-front.
            var items: [(x: Double, y: Double, scale: Double, seed: Int)] = []
            let visible = Array(trees.suffix(Self.capacity))
            for (i, seed) in visible.enumerated() {
                let slot = Self.slots[i]
                items.append(place(slot, seed: seed, w: w, h: h, grow: 1))
            }
            items.sort { $0.y < $1.y }
            for it in items { drawPlant(&ctx, it.x, it.y, it.scale, seed: it.seed) }

            // The plant growing during the current focus session, out front.
            if let g = growth {
                let x = w * 0.5, y = h * 0.97
                // little mound of soil
                ctx.fill(Path(ellipseIn: CGRect(x: x - 9, y: y - 3, width: 18, height: 6)),
                         with: .color(Color(red: 0.42, green: 0.3, blue: 0.2)))
                if g > 0.01 {
                    drawPlant(&ctx, x, y - 1, 0.3 + 1.2 * g, seed: trees.count &* 7919 &+ 1)
                }
            }

            if trees.count > Self.capacity {
                ctx.draw(Text("+\(trees.count - Self.capacity)").font(.caption2.bold()).foregroundColor(.white),
                         at: CGPoint(x: w - 16, y: 10))
            }
        }
    }

    private func place(_ slot: (x: Double, row: Int), seed: Int, w: Double, h: Double, grow: Double)
        -> (x: Double, y: Double, scale: Double, seed: Int) {
        let rowY = [0.58, 0.74, 0.9][slot.row]
        let rowScale = [0.8, 1.05, 1.3][slot.row]
        return (slot.x * w, rowY * h, rowScale * grow, seed)
    }

    private func drawPlant(_ ctx: inout GraphicsContext, _ x: Double, _ y: Double, _ s: Double, seed: Int) {
        var rng = SplitMix(seed)
        let kind = Int(rng.next() * 4)
        let greens: [Color] = [
            Color(red: 0.12, green: 0.42, blue: 0.22), Color(red: 0.18, green: 0.52, blue: 0.24),
            Color(red: 0.28, green: 0.6, blue: 0.28), Color(red: 0.14, green: 0.48, blue: 0.36),
        ]
        let green = greens[Int(rng.next() * Double(greens.count))]
        let trunk = Color(red: 0.45, green: 0.3, blue: 0.18)

        switch kind {
        case 0: // pine
            ctx.fill(Path(CGRect(x: x - 1.5 * s, y: y - 6 * s, width: 3 * s, height: 6 * s)), with: .color(trunk))
            for i in 0..<3 {
                let bw = (18 - 4 * Double(i)) * s
                let base = y - 5 * s - Double(i) * 7 * s
                var p = Path()
                p.move(to: CGPoint(x: x - bw / 2, y: base))
                p.addLine(to: CGPoint(x: x + bw / 2, y: base))
                p.addLine(to: CGPoint(x: x, y: base - 12 * s))
                p.closeSubpath()
                ctx.fill(p, with: .color(green))
            }
        case 1: // round deciduous
            ctx.fill(Path(CGRect(x: x - 1.8 * s, y: y - 12 * s, width: 3.6 * s, height: 12 * s)), with: .color(trunk))
            let r = 9 * s
            ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - 12 * s - r * 1.5, width: 2 * r, height: 2 * r)),
                     with: .color(green))
            ctx.fill(Path(ellipseIn: CGRect(x: x - r * 0.3, y: y - 12 * s - r * 1.5, width: r, height: r)),
                     with: .color(.white.opacity(0.12)))
        case 2: // bush
            for dx in [-5.0, 0, 5] {
                let r = (dx == 0 ? 7.0 : 5.5) * s
                ctx.fill(Path(ellipseIn: CGRect(x: x + dx * s - r, y: y - r * 1.6, width: 2 * r, height: 1.6 * r)),
                         with: .color(green))
            }
        default: // flower
            var stem = Path()
            stem.move(to: CGPoint(x: x, y: y))
            stem.addLine(to: CGPoint(x: x, y: y - 14 * s))
            ctx.stroke(stem, with: .color(greens[1]), lineWidth: 1.5 * s)
            ctx.fill(Path(ellipseIn: CGRect(x: x, y: y - 8 * s, width: 5 * s, height: 2.5 * s)), with: .color(greens[2]))
            let petals: [Color] = [.pink, .red, .purple, .orange, .white]
            let petal = petals[Int(rng.next() * Double(petals.count))]
            let cy = y - 14 * s, pr = 2.6 * s
            for k in 0..<5 {
                let a = Double(k) / 5 * 2 * .pi
                ctx.fill(Path(ellipseIn: CGRect(x: x + cos(a) * pr * 1.2 - pr, y: cy + sin(a) * pr * 1.2 - pr,
                                                width: 2 * pr, height: 2 * pr)), with: .color(petal))
            }
            ctx.fill(Path(ellipseIn: CGRect(x: x - pr * 0.8, y: cy - pr * 0.8, width: pr * 1.6, height: pr * 1.6)),
                     with: .color(.yellow))
        }
    }
}

/// Plant kind for a seed: 0 pine, 1 round tree, 2 bush, 3 flower (matches ForestView.drawPlant).
func plantKind(seed: Int) -> Int {
    var rng = SplitMix(seed)
    return Int(rng.next() * 4)
}
