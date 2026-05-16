#!/usr/bin/env swift
import Foundation
import CoreGraphics
import ImageIO

guard CommandLine.arguments.count >= 2 else {
    FileHandle.standardError.write(Data("usage: render_app_icon.swift <out.png>\n".utf8))
    exit(2)
}
let outPath = CommandLine.arguments[1]

let W = 1024, H = 1024
let cs = CGColorSpaceCreateDeviceRGB()
let ctx = CGContext(
    data: nil, width: W, height: H,
    bitsPerComponent: 8, bytesPerRow: W * 4, space: cs,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
)!

func rgb(_ r: Int, _ g: Int, _ b: Int, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: a)
}

// 1. Base background (BackgroundDeep #050807).
ctx.setFillColor(rgb(0x05, 0x08, 0x07))
ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))

// 2. Soft emerald glow behind the grid.
let bgColors = [rgb(0x12, 0x2E, 0x22), rgb(0x05, 0x08, 0x07)] as CFArray
let bgGrad = CGGradient(colorsSpace: cs, colors: bgColors, locations: [0, 1])!
ctx.drawRadialGradient(
    bgGrad,
    startCenter: CGPoint(x: CGFloat(W) * 0.42, y: CGFloat(H) * 0.62),
    startRadius: 0,
    endCenter: CGPoint(x: CGFloat(W) * 0.42, y: CGFloat(H) * 0.62),
    endRadius: CGFloat(W) * 0.75,
    options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
)

// 3. Grid geometry.
let cells = 5
let cellSize: CGFloat = 152
let gap: CGFloat = 20
let totalSize: CGFloat = CGFloat(cells) * cellSize + CGFloat(cells - 1) * gap
let gridX: CGFloat = (CGFloat(W) - totalSize) / 2
let gridY: CGFloat = (CGFloat(H) - totalSize) / 2
let radius: CGFloat = 30

// Anti-diagonal palette: top-left (strongest) -> bottom-right (weakest).
// Pulled from app tokens (ActionJam, ActionThreeBet, ActionRaise, ActionCall, ActionFold).
let bandColors: [CGColor] = [
    rgb(0xFF, 0x9A, 0x7A),  // 0 jam (coral)
    rgb(0xF2, 0xC4, 0x80),  // 1 jam->3bet blend
    rgb(0xDD, 0xFB, 0x7A),  // 2 3-bet (lime)
    rgb(0x9F, 0xF1, 0x95),  // 3 3bet->raise blend
    rgb(0x65, 0xF2, 0xB0),  // 4 raise (mint)
    rgb(0x68, 0xD5, 0xC8),  // 5 raise->call blend
    rgb(0x6F, 0xB8, 0xE0),  // 6 call (teal/blue)
    rgb(0x45, 0x70, 0x82),  // 7 call->fold blend
    rgb(0x2A, 0x2F, 0x33),  // 8 fold (muted)
]

// 4. Draw cells. visualRow 0 = top (strongest, high y in CG space).
for visualRow in 0..<cells {
    for col in 0..<cells {
        let band = visualRow + col
        let base = bandColors[band]
        let cellX = gridX + CGFloat(col) * (cellSize + gap)
        let cellY = gridY + CGFloat(cells - 1 - visualRow) * (cellSize + gap)
        let rect = CGRect(x: cellX, y: cellY, width: cellSize, height: cellSize)
        let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)

        // Drop shadow + fill.
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -6), blur: 14, color: rgb(0, 0, 0, 0.55))
        ctx.addPath(path)
        ctx.setFillColor(base)
        ctx.fillPath()
        ctx.restoreGState()

        // Top->mid highlight gradient for depth.
        ctx.saveGState()
        ctx.addPath(path)
        ctx.clip()
        let hiColors = [rgb(0xFF, 0xFF, 0xFF, 0.22), rgb(0xFF, 0xFF, 0xFF, 0.0)] as CFArray
        let hiGrad = CGGradient(colorsSpace: cs, colors: hiColors, locations: [0, 1])!
        ctx.drawLinearGradient(
            hiGrad,
            start: CGPoint(x: cellX, y: cellY + cellSize),
            end:   CGPoint(x: cellX, y: cellY + cellSize * 0.45),
            options: []
        )
        // Bottom inner shade for dim cells.
        let loColors = [rgb(0, 0, 0, 0.0), rgb(0, 0, 0, 0.18)] as CFArray
        let loGrad = CGGradient(colorsSpace: cs, colors: loColors, locations: [0, 1])!
        ctx.drawLinearGradient(
            loGrad,
            start: CGPoint(x: cellX, y: cellY + cellSize * 0.55),
            end:   CGPoint(x: cellX, y: cellY),
            options: []
        )
        ctx.restoreGState()
    }
}

// 5. Warm glow on the jam (top-left) cell so it reads as the focal point.
let jamX = gridX
let jamY = gridY + CGFloat(cells - 1) * (cellSize + gap)
let jamCenter = CGPoint(x: jamX + cellSize / 2, y: jamY + cellSize / 2)
ctx.saveGState()
ctx.setBlendMode(.plusLighter)
let glowColors = [rgb(0xFF, 0x9A, 0x7A, 0.32), rgb(0xFF, 0x9A, 0x7A, 0.0)] as CFArray
let glowGrad = CGGradient(colorsSpace: cs, colors: glowColors, locations: [0, 1])!
ctx.drawRadialGradient(
    glowGrad,
    startCenter: jamCenter, startRadius: 0,
    endCenter: jamCenter, endRadius: cellSize * 1.6,
    options: []
)
ctx.restoreGState()

// 6. Subtle vignette to push the corners back.
ctx.saveGState()
let vignetteColors = [rgb(0, 0, 0, 0.0), rgb(0, 0, 0, 0.45)] as CFArray
let vignetteGrad = CGGradient(colorsSpace: cs, colors: vignetteColors, locations: [0, 1])!
ctx.drawRadialGradient(
    vignetteGrad,
    startCenter: CGPoint(x: CGFloat(W) / 2, y: CGFloat(H) / 2),
    startRadius: CGFloat(W) * 0.35,
    endCenter: CGPoint(x: CGFloat(W) / 2, y: CGFloat(H) / 2),
    endRadius: CGFloat(W) * 0.78,
    options: []
)
ctx.restoreGState()

guard let image = ctx.makeImage() else {
    FileHandle.standardError.write(Data("failed to make image\n".utf8))
    exit(1)
}
let url = URL(fileURLWithPath: outPath)
guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
    FileHandle.standardError.write(Data("failed to create png destination\n".utf8))
    exit(1)
}
CGImageDestinationAddImage(dest, image, nil)
guard CGImageDestinationFinalize(dest) else {
    FileHandle.standardError.write(Data("failed to finalize png\n".utf8))
    exit(1)
}
print("Wrote \(url.path)")
