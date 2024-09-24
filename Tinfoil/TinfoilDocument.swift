//
//  TinfoilDocument.swift
//  Tinfoil
//
//  Created by Oliver Cameron on 20/9/2024.
//

import SwiftUI
import UniformTypeIdentifiers

struct TinfoilDocument: FileDocument {
    var text: String

    init(text: String = "<path d=\"M 10 10 H 90 V 90 H 10 Z\" />") {
        self.text = text
    }

    static var readableContentTypes: [UTType] { [.svg] }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)!
        return .init(regularFileWithContents: data)
    }
    func parseSVG() -> [any SVGsubunit] {
        var subunits: [any SVGsubunit] = []
        
        // Extract <path> elements
        let pathRegex = try! NSRegularExpression(pattern: "<path[^>]*d=\"([^\"]*)\"[^>]*>")
        let pathMatches = pathRegex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        
        for match in pathMatches {
            if let range = Range(match.range(at: 1), in: text) {
                let pathData = String(text[range])
                let svgPath = SVGpath(position: nil, pathData: pathData)
                subunits.append(svgPath)
            }
        }
        
        // Extract <text> elements
        let textRegex = try! NSRegularExpression(pattern: "<text[^>]*x=\"([^\"]*)\"[^>]*y=\"([^\"]*)\"[^>]*font-size=\"([^\"]*)\"[^>]*>([^<]*)</text>")
        let textMatches = textRegex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        
        for match in textMatches {
            if let xRange = Range(match.range(at: 1), in: text),
               let yRange = Range(match.range(at: 2), in: text),
               let fontSizeRange = Range(match.range(at: 3), in: text),
               let textRange = Range(match.range(at: 4), in: text) {
                let x = CGFloat(Double(text[xRange])!)
                let y = CGFloat(Double(text[yRange])!)
                let fontSize = CGFloat(Double(text[fontSizeRange])!)
                let text = String(text[textRange])
                let svgText = SVGtext(position: CGPoint(x: x, y: y), text: text, fontSize: fontSize)
                subunits.append(svgText)
            }
        }
        
        // Extract <ellipse> elements
        let ellipseRegex = try! NSRegularExpression(pattern: "<ellipse[^>]*cx=\"([^\"]*)\"[^>]*cy=\"([^\"]*)\"[^>]*rx=\"([^\"]*)\"[^>]*ry=\"([^\"]*)\"[^>]*>")
        let ellipseMatches = ellipseRegex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        
        for match in ellipseMatches {
            if let cxRange = Range(match.range(at: 1), in: text),
               let cyRange = Range(match.range(at: 2), in: text),
               let rxRange = Range(match.range(at: 3), in: text),
               let ryRange = Range(match.range(at: 4), in: text) {
                let cx = CGFloat(Double(text[cxRange])!)
                let cy = CGFloat(Double(text[cyRange])!)
                let rx = CGFloat(Double(text[rxRange])!)
                let ry = CGFloat(Double(text[ryRange])!)
                let svgEllipse = SVGellipse(position: CGPoint(x: cx, y: cy), rx: rx, ry: ry)
                subunits.append(svgEllipse)
            }
        }
        
        // Add more extraction logic for other SVG elements as needed
        
        return subunits
    }
}
protocol SVGsubunit: Identifiable, View {
    var id: UUID { get }
    var position: CGPoint? { get }
}

struct SVGpath: SVGsubunit {
    var id = UUID()
    var position: CGPoint?
    var pathData: String

    var body: some View {
        Path { path in
            // Parse pathData and create the path
            var currentPoint = CGPoint.zero
            var controlPoint = CGPoint.zero
            let commands = pathData.split(separator: " ")
            var index = 0

            while index < commands.count {
                let command = commands[index]
                switch command {
                case "M":
                    let x = CGFloat(Double(commands[index + 1])!)
                    let y = CGFloat(Double(commands[index + 2])!)
                    currentPoint = CGPoint(x: x, y: y)
                    path.move(to: currentPoint)
                    index += 3
                case "L":
                    let x = CGFloat(Double(commands[index + 1])!)
                    let y = CGFloat(Double(commands[index + 2])!)
                    currentPoint = CGPoint(x: x, y: y)
                    path.addLine(to: currentPoint)
                    index += 3
                case "Q":
                    let cx = CGFloat(Double(commands[index + 1])!)
                    let cy = CGFloat(Double(commands[index + 2])!)
                    let x = CGFloat(Double(commands[index + 3])!)
                    let y = CGFloat(Double(commands[index + 4])!)
                    controlPoint = CGPoint(x: cx, y: cy)
                    currentPoint = CGPoint(x: x, y: y)
                    path.addQuadCurve(to: currentPoint, control: controlPoint)
                    index += 5
                // Add more cases for other SVG commands as needed
                default:
                    index += 1
                }
            }
        }
        .stroke(Color.red, lineWidth: 1)
        .position(position ?? .zero)
    }
}

struct SVGtext: SVGsubunit {
    var id = UUID()
    var position: CGPoint?
    var text: String
    var fontSize: CGFloat

    var body: some View {
        Text(text)
            .font(.system(size: fontSize))
            .position(position ?? .zero)
    }
}

struct SVGellipse: SVGsubunit {
    var id = UUID()
    var position: CGPoint?
    var rx: CGFloat
    var ry: CGFloat

    var body: some View {
        Ellipse()
            .frame(width: rx * 2, height: ry * 2)
            .position(position ?? .zero)
    }
}

struct SVGgroup: SVGsubunit {
    var id = UUID()
    var position: CGPoint?
    var contents: [any SVGsubunit]

    var body: some View {
        ZStack {
            ForEach(contents, id: \.id) { content in
                AnyView(content)
                    .offset(CGSize(width: content.position?.x ?? 0, height: content.position?.y ?? 0))
            }
        }
    }
}


