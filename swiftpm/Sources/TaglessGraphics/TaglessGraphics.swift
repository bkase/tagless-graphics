//
//  TaglessGraphics.swift
//  TaglessGraphics
//
//  Created by Brandon Kase on 12/31/17.
//

import Foundation

protocol Drawing {
    static func rectangle(_ rect: CGRect, fill: CGColor) -> Self
    static func ellipse(in rect: CGRect, fill: CGColor) -> Self
    static func combined(_ layers: [Self]) -> Self
    static func alpha(_ alpha: CGFloat, _ child: Self) -> Self
}

extension Sequence where Iterator.Element: Drawing {
    var combined: Iterator.Element {
        return .combined(Array(self))
    }
}

protocol Gradient {
    // start point and end point are in the unit coordinate space
    static func gradient(in: CGRect, startPoint: CGPoint, endPoint: CGPoint, colors: [CGColor]) -> Self
}

func sample<D: Drawing>() -> D {
    return .combined([
        .ellipse(in: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)), fill: CGColor(red: 1.0, green: 0, blue: 0, alpha: 0)),
        .rectangle(CGRect(origin: CGPoint(x: 50, y: 50), size: CGSize(width: 100, height: 100)), fill: CGColor(red: 0, green: 0, blue: 1.0, alpha: 0))
        ])
}

