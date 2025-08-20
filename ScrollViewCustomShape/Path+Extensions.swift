//
//  Path+Extensions.swift
//  ScrollViewCustomShape
//
//  Created by Itsuki on 2025/08/20.
//

import SwiftUI

extension Path {
    nonisolated
    func point(at time: TimeInterval) -> CGPoint? {
        if time < 0 {
            return nil
        }
        if time > 1 {
            return nil
        }
        return self.trimmedPath(from: 0, to: time).currentPoint
    }
    
    // estimation of tangent using a line
    nonisolated
    func tangent(at time: TimeInterval) -> Angle {
        if time <= 0 || time >= 1 {
            return .zero
        }
        
        let estimationTimeDelta = 0.001

        guard let prev = self.point(at: max(0, time - estimationTimeDelta)),
              let next = self.point(at: min(1, time + estimationTimeDelta))
        else {
            return .zero
        }
        
        if (prev.x == next.x) {
            if next.y == prev.y {
                return .zero
            }
            
            if next.y > prev.y {
                return Angle(degrees: 90)
            }
            
            return Angle(degrees: -90)
        }
        
        let atan = atan2((next.y - prev.y), (next.x - prev.x))
        return Angle(radians: atan)
    }
  
    
    var approximateLength: CGFloat {
        let subdivisions: Int = 100
        var totalLength: CGFloat = 0.0
        guard let startPoint = self.startPoint else {
            return .zero
        }
        var currentPoint = startPoint

        self.forEach { element in
            switch element {
            case .move(to: let point):
                currentPoint = point
                
            case .line(to: let end):
                let start = currentPoint
                totalLength += hypot(end.x - start.x, end.y - start.y)
                currentPoint = end
                
            case .quadCurve(to: let end, control: let control):
                let start = currentPoint
                // Approximate quadratic Bezier curve with small line segments
                for i in 0..<subdivisions {
                    let t = CGFloat(i) / CGFloat(subdivisions)
                    let nextT = CGFloat(i + 1) / CGFloat(subdivisions)

                    let p1 = quadPointAtTime(start: start, end: end, control: control, t: t)
                    let p2 = quadPointAtTime(start: start, end: end, control: control, t: nextT)
                    
                    totalLength += hypot(p2.x - p1.x, p2.y - p1.y)
                }
                currentPoint = end
                
            case .curve(to: let end, control1: let control1, control2: let control2):
                let start = currentPoint

                // Approximate cubic Bezier curve with small line segments
                for i in 0..<subdivisions {
                    let t = CGFloat(i) / CGFloat(subdivisions)
                    let nextT = CGFloat(i + 1) / CGFloat(subdivisions)
                    let p1 = curvePointAtTime(start: start, end: end, control1: control1, control2: control2, t: t)
                    let p2 = curvePointAtTime(start: start, end: end, control1: control1, control2: control2, t: nextT)
                    totalLength += hypot(p2.x - p1.x, p2.y - p1.y)
                }
                currentPoint = end
            case .closeSubpath:
                let start = currentPoint
                let end = startPoint
                totalLength += hypot(end.x - start.x, end.y - start.y)
                currentPoint = startPoint
                break
            @unknown default:
                break
            }
        }
        return totalLength
    }
    
    private var startPoint: CGPoint? {
        if self.description.isEmpty {
            return nil
        }
        let descriptionArray = self.description.lowercased().components(separatedBy: CharacterSet.lowercaseLetters)
        guard let move = descriptionArray.first?.trimmingCharacters(in: .whitespaces) else {
            return nil
        }
        let pointsArray = move.components(separatedBy: .whitespaces)
        if pointsArray.count != 2 {
            return nil
        }
        guard let x = Double(pointsArray[0]),  let y = Double(pointsArray[1]) else {
            return nil
        }
        return CGPoint(x: x, y: y)
    }
    
    private func quadPointAtTime(start: CGPoint, end: CGPoint, control: CGPoint, t: CGFloat) -> CGPoint {
        let (startX, startY) = (start.x, start.y)
        let (endX, endY) = (end.x, end.y)
        let (controlX, controlY) = (control.x, control.y)

        let pointX = pow((1-t),2)*startX + 2*(1-t)*t*controlX + pow(t,2)*endX
        let pointY = pow((1-t),2)*startY + 2*(1-t)*t*controlY + pow(t,2)*endY
        return CGPoint(x: pointX, y: pointY)
    }
    
    private func curvePointAtTime(start: CGPoint, end: CGPoint, control1: CGPoint, control2: CGPoint, t: CGFloat) -> CGPoint {
        let (startX, startY) = (start.x, start.y)
        let (endX, endY) = (end.x, end.y)
        let (control1X, control1Y) = (control1.x, control1.y)
        let (control2X, control2Y) = (control2.x, control2.y)

        let pointX = pow((1-t),3)*startX + 3*pow((1-t),2)*t*control1X + 3*(1-t)*pow(t,2)*control2X + pow(t,3)*endX
        let pointY = pow((1-t),3)*startY + 3*pow((1-t),2)*t*control1Y + 3*(1-t)*pow(t,2)*control2Y + pow(t,3)*endY
        return CGPoint(x: pointX, y: pointY)
    }
}
