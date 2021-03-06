//
//  ViewController.swift
//  TaglessGraphics
//
//  Created by Chris Eidhof on 30.12.17.
//  Copyright © 2017 objc.io. All rights reserved.
//

import UIKit

// Let's say we want to create some drawings. Instead of a concrete representation, we'll create a protocol:

protocol Drawing {
    static func rectangle(_ rect: CGRect, fill: UIColor) -> Self
    static func ellipse(in rect: CGRect, fill: UIColor) -> Self
    static func combined(_ layers: [Self]) -> Self
    static func alpha(_ alpha: CGFloat, _ child: Self) -> Self
}

extension Sequence where Iterator.Element: Drawing {
    var combined: Iterator.Element {
        return .combined(Array(self))
    }
}

// We can draw in a CGContext:
struct CGraphics {
    let draw: (CGContext) -> ()
}

extension CGContext {
    func saveAndRestore(_ f: () -> ()) {
        saveGState()
        f()
        restoreGState()
    }
}

enum Svg {
    case node(name: String, args: [String: String], children: [Svg])
    case fragment([Svg])
    
    private func _render() -> String {
        switch self {
        case let .node(name, args, children):
            let nodePreamble = "<\(name) " + args.map{ k, v in "\(k)=\"\(v)\"" }.joined(separator: " ")
            if children.count == 0 {
                return nodePreamble + "/>"
            } else {
                return nodePreamble + ">\n" + children.map{ $0._render() }.joined(separator: "\n") + "\n" + "</\(name)>"
            }
        case let .fragment(nodes):
            return nodes.map { $0._render() }.joined(separator: "\n")
        }
    }
    
    /// Top-level render call that wraps the svg nodes in a <svg> tag
    func render(canvas: (width: Int, height: Int)) -> String {
        return Svg.node(
            name: "svg",
            args: ["width": String(describing: canvas.width), "height": String(describing: canvas.height)],
            children: [self]
        )._render()
    }
}
extension UIColor {
    var redValue: CGFloat{ return CIColor(color: self).red }
    var greenValue: CGFloat{ return CIColor(color: self).green }
    var blueValue: CGFloat{ return CIColor(color: self).blue }
    var alphaValue: CGFloat{ return CIColor(color: self).alpha }

    var rgb: String {
        return "rgb(\(Int(255 * redValue)), \(Int(255 * greenValue)), \(Int(255 * blueValue)))"
    }
}
extension Svg: Drawing {
    static func rectangle(_ rect: CGRect, fill: UIColor) -> Svg {
        return .node(
            name: "rect",
            args: [
                "x": String(describing: rect.origin.x),
                "y": String(describing: rect.origin.y),
                "width": String(describing: rect.width),
                "height": String(describing: rect.height),
                "fill": fill.rgb
            ],
            children: []
        )
    }
    
    static func ellipse(in rect: CGRect, fill: UIColor) -> Svg {
        return .node(
            name: "ellipse",
            args: [
                "x": String(describing: rect.origin.x),
                "y": String(describing: rect.origin.y),
                "rx": String(describing: rect.width),
                "ry": String(describing: rect.height),
                "fill": fill.rgb
            ],
            children: []
        )
    }
    
    static func combined(_ layers: [Svg]) -> Svg {
        return .fragment(layers)
    }
    
    static func alpha(_ alpha: CGFloat, _ child: Svg) -> Svg {
        // TODO: Need to make Svg aware of fill color, then this could modify the color to `rgba` instead of rgb
        fatalError("Todo")
    }
}

extension CGraphics: Drawing {
    static func rectangle(_ rect: CGRect, fill: UIColor) -> CGraphics {
        return CGraphics { context in
            context.saveAndRestore {
                context.setFillColor(fill.cgColor)
                context.fill(rect)
            }
        }
    }
    
    static func ellipse(in rect: CGRect, fill: UIColor) -> CGraphics {
        return CGraphics { context in
            context.saveAndRestore {
                context.setFillColor(fill.cgColor)
                context.fillEllipse(in: rect)
            }
        }

    }
    
    static func combined(_ layers: [CGraphics]) -> CGraphics {
        return CGraphics { context in
            layers.forEach { $0.draw(context) }
        }
    }
    
    static func alpha(_ alpha: CGFloat, _ child: CGraphics) -> CGraphics {
        return CGraphics { context in
            context.saveAndRestore {
                context.setAlpha(alpha)
                child.draw(context)
            }
        }
    }
}

// Alternatively, we could draw using CoreAnimation. This simple wrapper struct is necessary.
struct CoreAnimation {
    let render: () -> CALayer
}

extension CoreAnimation: Drawing {
    static func rectangle(_ rect: CGRect, fill: UIColor) -> CoreAnimation {
        return CoreAnimation {
            let result = CALayer()
            result.frame = rect
            result.backgroundColor = fill.cgColor
            return result
        }
    }
    
    static func ellipse(in rect: CGRect, fill: UIColor) -> CoreAnimation {
        return CoreAnimation {
            let result = CAShapeLayer()
            let path = UIBezierPath(ovalIn: rect)
            result.path = path.cgPath
            result.fillColor = fill.cgColor
            return result
        }
    }
    
    static func combined(_ layers: [CoreAnimation]) -> CoreAnimation {
        return CoreAnimation {
            let result = CALayer()
            for c in layers {
                result.addSublayer(c.render())
            }
            return result
        }
    }
    
    static func alpha(_ alpha: CGFloat, _ child: CoreAnimation) -> CoreAnimation {
        return CoreAnimation {
            let result = child.render()
            result.opacity = Float(alpha)
            return result
        }
    }
}

// Here is a sample drawing:

func sample<D: Drawing>() -> D {
    return .combined([
        .ellipse(in: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)), fill: .red),
        .rectangle(CGRect(origin: CGPoint(x: 50, y: 50), size: CGSize(width: 100, height: 100)), fill: .blue)
    ])
}

// Let's say we want to have drawings with drop shadows. We'll create a separate protocol:
protocol Shadow {
    static func shadow(opacity: CGFloat, offset: CGSize, radius: CGFloat, _ child: Self) -> Self
}

extension Shadow {
    // unfortunately, protocols don't allow default arguments
    static func shadow(_ child: Self) -> Self {
        return shadow(opacity: 0.75, offset: CGSize(width: 0, height: 3), radius: 3, child)
    }
}

protocol Gradient {
    // start point and end point are in the unit coordinate space
    static func gradient(in: CGRect, startPoint: CGPoint, endPoint: CGPoint, colors: [UIColor]) -> Self
}

extension CoreAnimation: Gradient {
    static func gradient(in frame: CGRect, startPoint: CGPoint, endPoint: CGPoint,
        colors: [UIColor]) -> CoreAnimation {
        return CoreAnimation {
            let result = CAGradientLayer()
            result.frame = frame
            result.startPoint = startPoint
            result.endPoint = endPoint
            result.colors = colors.map { $0.cgColor }
            return result
        }
    }
}

extension CGRect {
    func unitToAbsolute(point: CGPoint) -> CGPoint {
        return CGPoint(x: origin.x + width*point.x, y: origin.y + height*point.y)
    }
}

extension CGraphics: Gradient {
    static func gradient(in rect: CGRect, startPoint: CGPoint, endPoint: CGPoint, colors: [UIColor]) -> CGraphics {
        assert(colors.count > 1)
        let cgColors = colors.map { $0.cgColor } as CFArray
        let locationOffset = CGFloat(1) / CGFloat(colors.count-1)
        let locations = (0..<colors.count).map { CGFloat($0) * locationOffset }
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: cgColors, locations: locations)!
        let start = rect.unitToAbsolute(point: startPoint)
        let end = rect.unitToAbsolute(point: endPoint)
        return CGraphics { context in
            context.saveGState()
            context.clip(to: rect)
            context.drawLinearGradient(gradient, start: start, end: end, options: [])
            context.restoreGState()
        }
    }
    
    
}

func sample2<D: Drawing & Gradient>() -> D {
    return .combined([
        .ellipse(in: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)), fill: .red),
        .alpha(0.7, .gradient(in: CGRect(origin: CGPoint(x: 50, y: 50), size: CGSize(width: 100, height: 100)), startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 1, y: 1), colors: [UIColor.red, .green, .blue, .cyan]))
        ])
}


// Here's our abstract drawing. It now also requires the Shadow capability.
func sample3<D: Drawing & Shadow & Gradient>() -> D {
    return .combined([
        .shadow(.ellipse(in: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)), fill: .red)),
        .alpha(0.7, .gradient(in: CGRect(origin: CGPoint(x: 50, y: 50), size: CGSize(width: 100, height: 100)), startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 1, y: 1), colors: [UIColor.red, .green, .blue, .cyan]))
        ])
}

// We can't make Core Graphics conform (without manually drawing the shadow), but we *can* make Core Animation conform:
extension CoreAnimation: Shadow {
    static func shadow(opacity: CGFloat, offset: CGSize, radius: CGFloat, _ child: CoreAnimation) -> CoreAnimation {
        return CoreAnimation {
            let layer = child.render()
            layer.shadowOpacity = Float(opacity)
            layer.shadowRadius = radius
            layer.shadowOffset = offset
            return layer
        }
    }
}

class ViewController: UIViewController {
    let iv = UIImageView()
    override func viewDidLoad() {
        super.viewDidLoad()
        //view.addSubview(iv)
        let wv = UIWebView(frame: self.view.bounds)
        let svg: Svg = sample()
        let html = svg.render(canvas: (width: 300, height: 500))
        
        wv.loadHTMLString("<html>" + html + "</html>", baseURL: nil)
        wv.reload()
        view.addSubview(wv)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        /*iv.frame = view.bounds
        let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
        iv.image = renderer.image { context in
            let drawing: CGraphics = sample2()
            drawing.draw(context.cgContext)
        } */
    }
}

class CAViewController: UIViewController {
    override func viewWillAppear(_ animated: Bool) {
        let drawing: CoreAnimation = sample3()
        view.layer.addSublayer(drawing.render())
    }
}
