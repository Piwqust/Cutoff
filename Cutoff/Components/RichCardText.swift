import SwiftUI

@MainActor
struct RichCardText: View {
    let text: String
    var font: Font = AppTypography.body
    var foregroundColor: Color = AppColors.textPrimary
    var lineSpacing: CGFloat = 4
    
    var body: some View {
        buildRichText()
            .font(font)
            .foregroundStyle(foregroundColor)
            .lineSpacing(lineSpacing)
    }
    
    private func buildRichText() -> Text {
        let components = text.components(separatedBy: .whitespacesAndNewlines)
        var result = Text("")
        
        for (index, component) in components.enumerated() {
            guard !component.isEmpty else { continue }
            let space = index == components.count - 1 ? "" : " "
            
            if let parsed = parseCards(from: component) {
                result = result + parsed + Text(space)
            } else {
                result = result + Text(component + space)
            }
        }
        return result
    }
    
    private func parseCards(from string: String) -> Text? {
        let punctuation = CharacterSet.punctuationCharacters.subtracting(CharacterSet(charactersIn: "-+"))
        let trimmed = string.trimmingCharacters(in: punctuation)
        guard trimmed.count > 0 else { return nil }
        
        let nsString = string as NSString
        let range = nsString.range(of: trimmed)
        let pre = range.location > 0 ? nsString.substring(to: range.location) : ""
        let suf = (range.location + range.length) < nsString.length ? nsString.substring(from: range.location + range.length) : ""
        
        var generatedText: Text?
        
        if trimmed.contains("-") {
            let parts = trimmed.split(separator: "-")
            if parts.allSatisfy({ $0.count == 2 && Card(notation: String($0)) != nil }) {
                var localText = Text("")
                for (i, part) in parts.enumerated() {
                    if let card = Card(notation: String(part)) {
                        localText = localText + render(card: card)
                        if i < parts.count - 1 {
                            localText = localText + Text(" ")
                        }
                    }
                }
                generatedText = localText
            }
        } else if trimmed.count == 2 {
            if let card = Card(notation: trimmed) {
                generatedText = render(card: card)
            } else if HandCombo.parse(trimmed) != nil {
                generatedText = render(combo: trimmed)
            }
        } else if trimmed.count == 3 {
            let withoutPlus = trimmed.replacingOccurrences(of: "+", with: "")
            if HandCombo.parse(trimmed) != nil || HandCombo.parse(withoutPlus) != nil {
                generatedText = render(combo: trimmed)
            }
        } else if trimmed.count == 4 {
            let withoutPlus = trimmed.replacingOccurrences(of: "+", with: "")
            if let c1 = Card(notation: String(trimmed.prefix(2))),
               let c2 = Card(notation: String(trimmed.suffix(2))) {
                generatedText = render(card: c1) + Text(Image(systemName: "flexbox")) 
                generatedText = render(card: c1) + Text(" ") + render(card: c2)
            } else if HandCombo.parse(trimmed) != nil || HandCombo.parse(withoutPlus) != nil {
                generatedText = render(combo: trimmed)
            }
        }
        
        if let g = generatedText {
            return Text(pre) + g + Text(suf)
        }
        
        return nil
    }
    
    private func render(card: Card) -> Text {
        let view = CardView(card: card, size: .inline)
            .environment(\.colorScheme, .dark)
        
        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale
        
        if let uiImage = renderer.uiImage {
            return Text(Image(uiImage: uiImage)).baselineOffset(-6.0)
        }
        
        return Text(card.notation)
    }

    private func render(combo: String) -> Text {
        let view = ComboView(combo: combo, size: .inline)
            .environment(\.colorScheme, .dark)
        
        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale
        
        if let uiImage = renderer.uiImage {
            return Text(Image(uiImage: uiImage)).baselineOffset(-6.0)
        }
        
        return Text(combo)
    }
}
