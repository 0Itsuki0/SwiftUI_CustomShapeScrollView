//
//  ContentView.swift
//  ScrollViewCustomShape
//
//  Created by Itsuki on 2025/08/19.
//

import SwiftUI

struct ContentView: View {
    private var curve: Path {
        var path = Path()
        path.move(to: .init(x: 50, y: 100))
        path.addCurve(to: .init(x: 350, y: 100), control1: .init(x: 150, y: 200), control2: .init(x: 250, y: 0))
        return path
    }
    
    private var halfWheel: Path {
        var path = Path()
        path.addArc(center: .init(x: 200, y: 200), radius: 150, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        return path
    }
    
    private var verticalLine: Path {
        var path = Path()
        path.move(to: .init(x: 200, y: -100))
        path.addCurve(to: .init(x: 200, y: 200), control1: .init(x: 0, y: 0), control2: .init(x: 350, y: 100))
        return path
    }
    
    private let strokeStyle: StrokeStyle = .init(lineWidth: 36, lineCap: .round)
    private let strokeColor: Color = .red.opacity(0.8)
    
    
    var body: some View {
        NavigationStack {
            ScrollView {

                CustomShapeScrollView(axis: .horizontal, path: curve, strokeStyle: strokeStyle, background: .red, itemSpacing: 8, contentView: {
                    contents
                })
                .frame(height: curve.strokedPath(strokeStyle).boundingRect.height)

                Spacer()
                    .frame(height: 120)

                CustomShapeScrollView(axis: .horizontal, path: halfWheel, strokeStyle: strokeStyle, background: .yellow, itemSpacing: 8, contentView: {
                    contents
                })
                .frame(height: halfWheel.strokedPath(strokeStyle).boundingRect.height)

                Spacer()
                    .frame(height: 200)
                
                CustomShapeScrollView(axis: .vertical, path: verticalLine, strokeStyle: strokeStyle, background: .mint, itemSpacing: 8, contentView: {
                    contents
                })
                .frame(height: verticalLine.strokedPath(strokeStyle).boundingRect.height)
                   
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.green.opacity(0.2))
            .toolbar {
                ToolbarItem(placement: .principal, content: {
                    Text("Custom ScrollView")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 48)
                })
                 ToolbarItem(placement: .subtitle) {
                     Text("Follow Custom Path, Of Custom Shape")
                         .font(.title3)
                         .fontWeight(.semibold)
                 }
             }
        }
    }
    
    
    nonisolated
    var contents: some View {
        ForEach(0...30, id: \.self) { index in
            Text(String(index))
                .padding(.all, 2)
                .frame(width: 24)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(.white)
                .background(RoundedRectangle(cornerRadius: 2).fill(.blue))
            
        }
    }
}


struct CustomShapeScrollView<V: View, S: ShapeStyle>: View {
    var axis: Axis
    var path: Path
    var strokeStyle: StrokeStyle
    var background: S
    
    var itemSpacing: CGFloat = 8.0
    
    @ViewBuilder var contentView: V

    
    var body: some View {
        path
            .stroke(background, style: strokeStyle)
            .overlay(alignment: .center, content: {
                self.scrollView
            })
    }
    
    var scrollView: some View {
        let axes: Axis.Set = axis == .horizontal ? .horizontal : .vertical
        let pathLength: CGFloat = path.approximateLength
        let subviews = self.makeSubviews(pathLength: pathLength)
        let boundingRect = path.strokedPath(strokeStyle).boundingRect
        
        return GeometryReader { geometry in
            ScrollView(axes, content: {
                if self.axis == .horizontal {
                    HStack(spacing: itemSpacing, content: {
                        subviews

                    })
                    .frame(height: boundingRect.size.height, alignment: .topLeading)
                    .scrollTargetLayout()

                } else {
                    VStack(spacing: itemSpacing, content: {
                        subviews
                    })
                    .frame(width: boundingRect.size.width, alignment: .topLeading)
                    .scrollTargetLayout()

                }
         
            })
            .offset(x: boundingRect.minX, y: boundingRect.minY)
            .scrollIndicators(.hidden)
            .defaultScrollAnchor(.leading, for: .alignment)
            .defaultScrollAnchor(.leading, for: .initialOffset)
            .defaultScrollAnchor(.leading, for: .sizeChanges)
            .safeAreaPadding(
                axis == .horizontal ? .trailing : .bottom,
                max(0, (axis == .horizontal ? geometry.size.width : geometry.size.height) - pathLength)
            )
            .clipShape(path.stroke(style: strokeStyle))
            .contentShape(path.stroke(style: strokeStyle))

        }

    }
    
    func makeSubviews(pathLength: CGFloat) -> some View {
        let timePerLength: CGFloat = 1/pathLength
        let path = path
        let axis = axis
        let boundingRect = path.strokedPath(strokeStyle).boundingRect

        return ForEach(subviews: contentView) { subview in
            subview
                .visualEffect({  content, geometry in

                    let frame = geometry.frame(in: .scrollView(axis: axis))

                    let timeTick: CGFloat = switch axis {
                    case .horizontal:
                        frame.midX * timePerLength
                    case .vertical:
                        frame.midY * timePerLength
                    }
                    
                    var tangent: Angle = path.tangent(at: timeTick)
                    if axis == .vertical {
                        tangent = tangent - .degrees(90)
                    }
                    let point: CGPoint? = path.point(at: timeTick)
                    let (offsetX, offsetY) = if let point = point {
                        (point.x - frame.midX, point.y - frame.midY)
                    } else {
                        (0, 0)
                    }
                    return content
                        .rotationEffect(tangent, anchor: .center)
                        .offset(x: offsetX, y: offsetY)
                        .offset(x: -boundingRect.minX, y: -boundingRect.minY)

                })
        }

    }
}




#Preview {
    ContentView()
}
