#!/usr/bin/env swift
//
// Cutoff app icon — a thick mint-glass "C" ring with the opening on
// the right cut at a clean diagonal. Liquid-Glass specular sweep on
// the upper-left curve; bright bevel on each cut endpoint.
//
// Usage: swift render_icon.swift <output.png>
//

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let size: CGFloat = 1024

guard CommandLine.arguments.count >= 2 else {
    FileHandle.standardError.write("usage: render_icon.swift <output.png>\n".data(using: .utf8)!)
    exit(1)
}
let outPath = CommandLine.arguments[1]

let space = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(
    data: nil,
    width: Int(size),
    height: Int(size),
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: space,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fatalError("CGContext failed")
}

func rgb(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1.0) -> CGColor {
    CGColor(red: r, green: g, blue: b, alpha: a)
}

// ────────── Backdrop ──────────
ctx.setFillColor(rgb(0.020, 0.045, 0.040))
ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))

let bgColors = [
    rgb(0.070, 0.140, 0.125),
    rgb(0.018, 0.045, 0.040),
] as CFArray
let bgGrad = CGGradient(colorsSpace: space, colors: bgColors, locations: [0.0, 1.0])!
ctx.drawLinearGradient(
    bgGrad,
    start: CGPoint(x: size / 2, y: size),
    end: CGPoint(x: size / 2, y: 0),
    options: []
)

let center = CGPoint(x: size / 2, y: size / 2)
let outerR: CGFloat = 380
let innerR: CGFloat = 235

// Opening: clean wedge on the right side. Angle range in radians (CG math:
// 0 = right, +y up, CCW positive).
let openHalf: CGFloat = .pi / 7.0          // ~25° each side of right
let openTop: CGFloat = openHalf            // upper edge of the cut
let openBot: CGFloat = -openHalf           // lower edge of the cut

// ────────── Soft outer mint glow that follows the ring ──────────
//
// Stroke a wide soft path along the ring's median radius to give a
// halo only where the ring lives — avoids the "ghost disc" problem.
ctx.saveGState()
ctx.setStrokeColor(rgb(0.45, 0.95, 0.80, 0.30))
ctx.setLineWidth(outerR - innerR + 120)
ctx.setLineCap(.round)
let midR = (outerR + innerR) / 2
ctx.addArc(
    center: center,
    radius: midR,
    startAngle: openTop,
    endAngle: openBot,
    clockwise: false                       // CCW the long way around
)
ctx.strokePath()
ctx.restoreGState()

// ────────── Build the C-ring path (kept region) ──────────
//
// Outer arc (CCW the long way) from openTop to openBot, then inner arc
// back (CW the long way), close.
let ring = CGMutablePath()
let outerStart = CGPoint(x: center.x + cos(openTop) * outerR, y: center.y + sin(openTop) * outerR)
ring.move(to: outerStart)
ring.addArc(center: center, radius: outerR, startAngle: openTop, endAngle: openBot, clockwise: false)
ring.addLine(to: CGPoint(x: center.x + cos(openBot) * innerR, y: center.y + sin(openBot) * innerR))
ring.addArc(center: center, radius: innerR, startAngle: openBot, endAngle: openTop, clockwise: true)
ring.closeSubpath()

// ────────── Fill the ring with mint→emerald gradient ──────────
ctx.saveGState()
ctx.addPath(ring)
ctx.clip()

let mintColors = [
    rgb(0.68, 0.99, 0.87),   // top
    rgb(0.40, 0.88, 0.72),
    rgb(0.18, 0.62, 0.50),   // bottom
] as CFArray
let mint = CGGradient(colorsSpace: space, colors: mintColors, locations: [0.0, 0.5, 1.0])!
ctx.drawLinearGradient(
    mint,
    start: CGPoint(x: center.x, y: center.y + outerR),
    end:   CGPoint(x: center.x, y: center.y - outerR),
    options: []
)

// Liquid-Glass specular sweep on the upper-left of the C
let specColors = [
    rgb(1, 1, 1, 0.65),
    rgb(1, 1, 1, 0.20),
    rgb(1, 1, 1, 0.0),
] as CFArray
let spec = CGGradient(colorsSpace: space, colors: specColors, locations: [0.0, 0.55, 1.0])!
ctx.drawLinearGradient(
    spec,
    start: CGPoint(x: center.x - outerR * 0.9,  y: center.y + outerR * 0.7),
    end:   CGPoint(x: center.x - outerR * 0.05, y: center.y + outerR * 0.15),
    options: []
)

// Inner-edge darkening: a subtle dark band along the inner rim to give
// the ring physical depth.
ctx.setBlendMode(.multiply)
let innerShadeColors = [
    rgb(0.04, 0.12, 0.09, 0.60),   // dark at inner
    rgb(0.04, 0.12, 0.09, 0.0),    // fade out toward middle
] as CFArray
let innerShade = CGGradient(colorsSpace: space, colors: innerShadeColors, locations: [0.0, 1.0])!
ctx.drawRadialGradient(
    innerShade,
    startCenter: center, startRadius: innerR,
    endCenter: center, endRadius: innerR + 70,
    options: []
)

// Outer rim darkening for the same reason
let outerShadeColors = [
    rgb(0.04, 0.12, 0.09, 0.0),
    rgb(0.04, 0.12, 0.09, 0.50),
] as CFArray
let outerShade = CGGradient(colorsSpace: space, colors: outerShadeColors, locations: [0.0, 1.0])!
ctx.drawRadialGradient(
    outerShade,
    startCenter: center, startRadius: outerR - 70,
    endCenter: center, endRadius: outerR,
    options: []
)
ctx.setBlendMode(.normal)

ctx.restoreGState()

// ────────── Cut bevel highlights ──────────
//
// Each end of the C was "cut" — paint a bright thin sliver on each
// radial cut face so the eye reads it as freshly cleaved glass.

func paintCutFace(_ angle: CGFloat) {
    // Cut face is the line segment from inner radius to outer radius
    // at the given angle.
    let pInner = CGPoint(x: center.x + cos(angle) * innerR, y: center.y + sin(angle) * innerR)
    let pOuter = CGPoint(x: center.x + cos(angle) * outerR, y: center.y + sin(angle) * outerR)

    // Soft halo
    ctx.saveGState()
    ctx.addPath(ring)
    ctx.clip()
    ctx.setLineCap(.round)
    ctx.setStrokeColor(rgb(0.90, 1.0, 0.95, 0.35))
    ctx.setLineWidth(26)
    ctx.move(to: pInner)
    ctx.addLine(to: pOuter)
    ctx.strokePath()
    ctx.restoreGState()

    // Bright core
    ctx.saveGState()
    ctx.addPath(ring)
    ctx.clip()
    ctx.setLineCap(.butt)
    ctx.setStrokeColor(rgb(0.98, 1.0, 0.99, 1.0))
    ctx.setLineWidth(7)
    ctx.move(to: pInner)
    ctx.addLine(to: pOuter)
    ctx.strokePath()
    ctx.restoreGState()

    // Tiny bright dot at the outer endpoint
    ctx.saveGState()
    ctx.setFillColor(rgb(1, 1, 1, 0.95))
    ctx.fillEllipse(in: CGRect(x: pOuter.x - 5, y: pOuter.y - 5, width: 10, height: 10))
    ctx.restoreGState()
}

paintCutFace(openTop)
paintCutFace(openBot)

// ────────── Thin bright rim highlight on the upper-outer curve ──────────
ctx.saveGState()
ctx.setStrokeColor(rgb(1, 1, 1, 0.65))
ctx.setLineWidth(3)
ctx.addArc(
    center: center,
    radius: outerR - 2,
    startAngle: .pi * (130.0 / 180.0),
    endAngle: .pi * (190.0 / 180.0),
    clockwise: false
)
ctx.strokePath()
ctx.restoreGState()

// ────────── Save ──────────
guard let image = ctx.makeImage() else { fatalError("makeImage") }
let outURL = URL(fileURLWithPath: outPath)
guard let dest = CGImageDestinationCreateWithURL(outURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    fatalError("destination")
}
CGImageDestinationAddImage(dest, image, nil)
guard CGImageDestinationFinalize(dest) else { fatalError("finalize") }
print("wrote \(outURL.path)")
