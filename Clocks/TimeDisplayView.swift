//
//  TimeDisplayView.swift
//  Clocks
//
//  Created by Matt Gallagher on 2017/08/18.
//  Copyright © 2017 Matt Gallagher. All rights reserved.
//

import UIKit

class TimeDisplayView: UIView {
	var components: (hours: Int, minutes: Int, seconds: Int) { didSet { setNeedsDisplay() } }
	
	override init(frame: CGRect) {
		components = (0, 0, 0)
		super.init(frame: frame)
	}
 	
	required init?(coder aDecoder: NSCoder) {
		components = (0, 0, 0)
		super.init(coder: aDecoder)
	}
	
	override func layoutSubviews() {
		self.setNeedsDisplay()
	}
	
	override func draw(_ rect: CGRect) {
		let radius = 0.4 * min(self.bounds.width, self.bounds.height)
		let centerX = 0.5 * self.bounds.width + self.bounds.minX
		let centerY = 0.5 * self.bounds.height + self.bounds.minY
		
		let small = radius < 50
		
		let background = UIBezierPath(ovalIn: CGRect(x: centerX - 1.0 * radius, y: centerY - 1.0 * radius, width: 2.0 * radius, height: 2.0 * radius))
		if let context = UIGraphicsGetCurrentContext() {
			let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [UIColor(red: 0.93, green: 0.93, blue: 0.682, alpha: 0.5).cgColor, UIColor(red: 0.79, green: 0.835, blue: 0.912, alpha: 0.5).cgColor] as CFArray, locations: nil)!
			background.addClip()
			context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: centerY - radius), end: CGPoint(x: 0, y: centerY + radius), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
		}
		
		let ticks = UIBezierPath()
		for i in 0...11 {
			let angle = -2 * CGFloat.pi * CGFloat(i) / 12 - 0.5 * CGFloat.pi
			ticks.move(to: CGPoint(x: centerX + radius * sin(angle), y: centerY + radius * cos(angle)))
			ticks.addLine(to: CGPoint(x: centerX + 0.75 * radius * sin(angle), y: centerY + 0.75 * radius * cos(angle)))
		}
		UIColor.lightGray.setStroke()
		ticks.lineWidth = 1.0
		ticks.stroke()

		let border = UIBezierPath(ovalIn: CGRect(x: centerX - 1.0 * radius, y: centerY - 1.0 * radius, width: 2.0 * radius, height: 2.0 * radius))
		UIColor(white: 0.3, alpha: 1).setStroke()
		border.lineWidth = small ? 1.0 : 6.0
		border.stroke()
		
		let hour = UIBezierPath()
		let hourAngle = -2 * CGFloat.pi * (CGFloat(components.hours) + (CGFloat(components.minutes) / 60) + (CGFloat(components.seconds) / 3600)) / 12 - 1.0 * CGFloat.pi
		hour.move(to: CGPoint(x: centerX, y: centerY))
		hour.addLine(to: CGPoint(x: centerX + 0.5 * radius * sin(hourAngle), y: centerY + 0.5 * radius * cos(hourAngle)))
		UIColor.black.setStroke()
		hour.lineWidth = small ? 2.0 : 4.0
		hour.lineCapStyle = .round
		hour.stroke()
		
		let minute = UIBezierPath()
		let minuteAngle = -2 * CGFloat.pi * (CGFloat(components.minutes) + (CGFloat(components.seconds) / 60)) / 60 - 1.0 * CGFloat.pi
		minute.move(to: CGPoint(x: centerX, y: centerY))
		minute.addLine(to: CGPoint(x: centerX + 0.8 * radius * sin(minuteAngle), y: centerY + 0.8 * radius * cos(minuteAngle)))
		UIColor.darkGray.setStroke()
		minute.lineWidth = small ? 1.0 : 2.5
		minute.lineCapStyle = .round
		minute.stroke()
		
		let second = UIBezierPath()
		let secondAngle = -2 * CGFloat.pi * CGFloat(components.seconds) / 60 - 1.0 * CGFloat.pi
		second.move(to: CGPoint(x: centerX, y: centerY))
		second.addLine(to: CGPoint(x: centerX + 0.9 * radius * sin(secondAngle), y: centerY + 0.9 * radius * cos(secondAngle)))
		UIColor.red.setStroke()
		second.lineWidth = small ? 0.5 : 1.0
		second.stroke()
	}

}
