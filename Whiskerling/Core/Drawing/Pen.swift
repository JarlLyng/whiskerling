import SwiftUI

/// A small HTML-canvas-style wrapper around `GraphicsContext`.
///
/// The game was first written as a web page, and this keeps the drawing code close to that
/// version: build a path, then fill or stroke it with the current style. `save()` and
/// `restore()` push and pop the whole drawing state, including transforms and clipping.
final class Pen {
    private struct State {
        var ctx: GraphicsContext
        var fill: GraphicsContext.Shading = .color(.black)
        var stroke: GraphicsContext.Shading = .color(.black)
        var lineWidth: CGFloat = 1
        var lineCap: CGLineCap = .round
        var lineJoin: CGLineJoin = .round
        var dash: [CGFloat] = []
    }

    private var state: State
    private var stack: [State] = []
    private(set) var path = Path()

    init(_ ctx: GraphicsContext) {
        state = State(ctx: ctx)
    }

    // MARK: State

    func save() { stack.append(state) }
    func restore() { if let last = stack.popLast() { state = last } }

    func translate(_ x: CGFloat, _ y: CGFloat) { state.ctx.translateBy(x: x, y: y) }
    func scale(_ x: CGFloat, _ y: CGFloat) { state.ctx.scaleBy(x: x, y: y) }
    func rotate(_ radians: CGFloat) { state.ctx.rotate(by: .radians(Double(radians))) }

    var alpha: Double {
        get { state.ctx.opacity }
        set { state.ctx.opacity = newValue }
    }

    var fillColor: Color {
        get { .black }
        set { state.fill = .color(newValue) }
    }
    var strokeColor: Color {
        get { .black }
        set { state.stroke = .color(newValue) }
    }
    var lineWidth: CGFloat {
        get { state.lineWidth }
        set { state.lineWidth = newValue }
    }
    var lineCap: CGLineCap {
        get { state.lineCap }
        set { state.lineCap = newValue }
    }
    var dash: [CGFloat] {
        get { state.dash }
        set { state.dash = newValue }
    }

    func fillGradient(_ colors: [Color], from: CGPoint, to: CGPoint) {
        state.fill = .linearGradient(Gradient(colors: colors), startPoint: from, endPoint: to)
    }

    /// A round gradient from the centre (`location` 0) out to `radius` (1).
    func fillRadial(_ stops: [Gradient.Stop], center: CGPoint = .zero, radius: CGFloat) {
        state.fill = .radialGradient(Gradient(stops: stops), center: center, startRadius: 0, endRadius: radius)
    }

    // MARK: Paths

    func beginPath() { path = Path() }
    func moveTo(_ x: CGFloat, _ y: CGFloat) { path.move(to: CGPoint(x: x, y: y)) }
    func lineTo(_ x: CGFloat, _ y: CGFloat) {
        if path.isEmpty { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
    }
    func quadTo(_ cx: CGFloat, _ cy: CGFloat, _ x: CGFloat, _ y: CGFloat) {
        path.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: cx, y: cy))
    }
    func bezierTo(_ c1x: CGFloat, _ c1y: CGFloat, _ c2x: CGFloat, _ c2y: CGFloat, _ x: CGFloat, _ y: CGFloat) {
        path.addCurve(to: CGPoint(x: x, y: y), control1: CGPoint(x: c1x, y: c1y), control2: CGPoint(x: c2x, y: c2y))
    }
    func closePath() { path.closeSubpath() }
    func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) { path.addRect(CGRect(x: x, y: y, width: w, height: h)) }

    /// Like canvas `arc()`: angles grow clockwise on screen unless `ccw` is set.
    func arc(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ a0: CGFloat, _ a1: CGFloat, ccw: Bool = false) {
        path.addArc(center: CGPoint(x: x, y: y), radius: max(r, 0.1),
                    startAngle: .radians(Double(a0)), endAngle: .radians(Double(a1)), clockwise: ccw)
    }

    /// Like canvas `ellipse()`. A full turn adds a closed ellipse; a part adds an arc.
    func ellipse(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat, rot: CGFloat = 0,
                 from a0: CGFloat = 0, to a1: CGFloat = .pi * 2, ccw: Bool = false) {
        let t = CGAffineTransform(translationX: x, y: y).rotated(by: rot).scaledBy(x: max(rx, 0.1), y: max(ry, 0.1))
        if a0 == 0 && a1 >= .pi * 2 - 0.0001 && !ccw {
            path.addEllipse(in: CGRect(x: -1, y: -1, width: 2, height: 2), transform: t)
        } else {
            path.addArc(center: .zero, radius: 1, startAngle: .radians(Double(a0)), endAngle: .radians(Double(a1)),
                        clockwise: ccw, transform: t)
        }
    }

    func roundRect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) {
        let rr = min(r, w / 2, h / 2)
        path.addRoundedRect(in: CGRect(x: x, y: y, width: w, height: h), cornerSize: CGSize(width: rr, height: rr))
    }

    // MARK: Drawing

    func fill(evenOdd: Bool = false) { state.ctx.fill(path, with: state.fill, style: FillStyle(eoFill: evenOdd)) }
    func stroke() {
        state.ctx.stroke(path, with: state.stroke,
                         style: StrokeStyle(lineWidth: state.lineWidth, lineCap: state.lineCap,
                                            lineJoin: state.lineJoin, dash: state.dash))
    }
    func clip() { state.ctx.clip(to: path) }

    func fill(_ color: Color) { fillColor = color; fill() }
    func stroke(_ color: Color, _ width: CGFloat) { strokeColor = color; lineWidth = width; stroke() }

    func fillRect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) {
        state.ctx.fill(Path(CGRect(x: x, y: y, width: w, height: h)), with: state.fill)
    }
    func strokeRect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) {
        state.ctx.stroke(Path(CGRect(x: x, y: y, width: w, height: h)), with: state.stroke,
                         style: StrokeStyle(lineWidth: state.lineWidth, lineCap: state.lineCap, lineJoin: state.lineJoin))
    }

    // MARK: Text

    private func label(_ string: String, size: CGFloat, weight: Font.Weight, color: Color) -> Text {
        Text(verbatim: string).font(.system(size: size, weight: weight, design: .rounded)).foregroundStyle(color)
    }
    func text(_ string: String, _ x: CGFloat, _ y: CGFloat, size: CGFloat, weight: Font.Weight = .bold, color: Color) {
        state.ctx.draw(label(string, size: size, weight: weight, color: color), at: CGPoint(x: x, y: y), anchor: .center)
    }
    func measure(_ string: String, size: CGFloat, weight: Font.Weight = .bold) -> CGSize {
        state.ctx.resolve(label(string, size: size, weight: weight, color: .black))
            .measure(in: CGSize(width: 10_000, height: 10_000))
    }

    // MARK: Shape helpers used everywhere

    func ell(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ rot: CGFloat = 0) {
        beginPath(); ellipse(x, y, rx, ry, rot: rot)
    }
    func circ(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) {
        beginPath(); arc(x, y, r, 0, .pi * 2)
    }
    func rr(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) {
        beginPath(); roundRect(x, y, w, h, r)
    }
}

extension Color {
    init(hex: String, alpha: Double = 1) {
        var s = hex
        if s.hasPrefix("#") { s.removeFirst() }
        let v = UInt32(s, radix: 16) ?? 0
        self.init(.sRGB, red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255,
                  blue: Double(v & 0xFF) / 255, opacity: alpha)
    }

    static func rgba(_ r: Double, _ g: Double, _ b: Double, _ a: Double) -> Color {
        Color(.sRGB, red: r / 255, green: g / 255, blue: b / 255, opacity: a)
    }
}
