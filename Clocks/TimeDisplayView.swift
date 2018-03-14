//
//  TimeDisplayView.swift
//  Clocks
//
//  Created by Matt Gallagher on 2017/08/18.
//  Copyright © 2017 Matt Gallagher. All rights reserved.
//
//  Permission to use, copy, modify, and/or distribute this software for any purpose with or without
//  fee is hereby granted, provided that the above copyright notice and this permission notice
//  appear in all copies.
//
//  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS
//  SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
//  AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
//  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
//  NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE
//  OF THIS SOFTWARE.
//

import CwlViews

class TimeDisplay: ViewInstance {
	var state: BinderState<UIView, Signal<Row>>
	init(row: Signal<Row>) {
		self.state = .pending(row)
	}
	public func view() -> Layout.View {
		return state.construct { row in
			let v = View(subclass: TimeDisplayView.self, .backgroundColor -- .clear)
			let b = row.adhocBinding(toType: TimeDisplayView.self) {
				$0.components = $1.current
			}
			return v.instance(additional: b)
		}
	}
}

fileprivate class TimeDisplayView: UIView {
	var components: DateComponents { didSet { setNeedsDisplay() } }
	
	override init(frame: CGRect) {
		components = DateComponents(hour: 0, minute: 0, second: 0)
		super.init(frame: frame)
	}
	
	required init?(coder aDecoder: NSCoder) {
		components = DateComponents(hour: 0, minute: 0, second: 0)
		super.init(coder: aDecoder)
	}
	
	override func layoutSubviews() {
		self.setNeedsDisplay()
	}
	
	func radialMark(center: CGPoint, outerRadius: CGFloat, innerRadius: CGFloat, sixtieths: CGFloat, color: UIColor, lineWidth: CGFloat) {
		let path = UIBezierPath()
		let angle = -(2 * sixtieths / 60 + 1) * CGFloat.pi
		path.move(to: CGPoint(x: center.x + innerRadius * sin(angle), y: center.y + innerRadius * cos(angle)))
		path.addLine(to: CGPoint(x: center.x + outerRadius * sin(angle), y: center.y + outerRadius * cos(angle)))
		color.setStroke()
		path.lineWidth = lineWidth
		path.lineCapStyle = .round
		path.stroke()
	}
	
	override func draw(_ rect: CGRect) {
		let radius = 0.4 * min(self.bounds.width, self.bounds.height)
		let center = CGPoint(x: 0.5 * self.bounds.width + self.bounds.minX, y: 0.5 * self.bounds.height + self.bounds.minY)
		
		let small = radius < 50
		
		let background = UIBezierPath(ovalIn: CGRect(x: center.x - 1.0 * radius, y: center.y - 1.0 * radius, width: 2.0 * radius, height: 2.0 * radius))
		if let context = UIGraphicsGetCurrentContext() {
			let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [UIColor(red: 0.93, green: 0.93, blue: 0.682, alpha: 0.5).cgColor, UIColor(red: 0.79, green: 0.835, blue: 0.912, alpha: 0.5).cgColor] as CFArray, locations: nil)!
			background.addClip()
			context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: center.y - radius), end: CGPoint(x: 0, y: center.y + radius), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
		}
		
		for i in 0...11 {
			radialMark(center: center, outerRadius: radius, innerRadius: 0.75 * radius, sixtieths: CGFloat(i) * 5, color: UIColor.lightGray, lineWidth: 1)
		}
		
		let border = UIBezierPath(ovalIn: CGRect(x: center.x - 1.0 * radius, y: center.y - 1.0 * radius, width: 2.0 * radius, height: 2.0 * radius))
		UIColor(white: 0.3, alpha: 1).setStroke()
		border.lineWidth = small ? 1.0 : 6.0
		border.stroke()
		
		radialMark(center: center, outerRadius: 0.5 * radius, innerRadius: 0, sixtieths: 5 * CGFloat(components.hour ?? 0) + CGFloat(components.minute ?? 0) / 12 + CGFloat(components.second ?? 0) / 720, color: UIColor.black, lineWidth: small ? 2.0 : 4.0)
		radialMark(center: center, outerRadius: 0.8 * radius, innerRadius: 0, sixtieths: CGFloat(components.minute ?? 0) + CGFloat(components.second ?? 0) / 60, color: UIColor.darkGray, lineWidth: small ? 1.0 : 2.5)
		radialMark(center: center, outerRadius: 0.9 * radius, innerRadius: 0, sixtieths: CGFloat(components.second ?? 0), color: UIColor.red, lineWidth: small ? 0.5 : 1.0)
	}
}
