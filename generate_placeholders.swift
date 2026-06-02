import Cocoa

func createImage(color: NSColor, path: String) {
    let size = NSSize(width: 1024, height: 1024)
    let image = NSImage(size: size)
    image.lockFocus()
    color.setFill()
    NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
    image.unlockFocus()
    
    guard let tiffRepresentation = image.tiffRepresentation,
          let bitmapImage = NSBitmapImageRep(data: tiffRepresentation),
          let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
        return
    }
    
    try? pngData.write(to: URL(fileURLWithPath: path))
}

createImage(color: NSColor(red: 0.2, green: 0.9, blue: 0.5, alpha: 1.0), path: "AppIconPreviewNeon.png")
createImage(color: NSColor(red: 0.1, green: 0.3, blue: 0.2, alpha: 1.0), path: "AppIconPreviewDark.png")
