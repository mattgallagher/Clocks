//
//  HistoryViewController.swift
//  Clocks
//
//  Created by Matt Gallagher on 2017/08/19.
//  Copyright © 2017 Matt Gallagher. All rights reserved.
//

import UIKit

class HistoryViewController: UIViewController {
	var overlayWindow: UIWindow
	var slider: UISlider
	var label: UILabel
	
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		overlayWindow = UIWindow()
		slider = UISlider()
		label = UILabel()
		
		super.init(nibName: nil, bundle: nil)
		
		// Force a view load
		_ = self.view
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func loadView() {
		let window = UIApplication.shared.windows.first!
		overlayWindow.backgroundColor = .clear
		overlayWindow.isOpaque = false
		overlayWindow.frame = CGRect(x: window.frame.origin.x, y: window.frame.origin.y + window.frame.size.height - 56, width: window.frame.size.width, height: 56)
		overlayWindow.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
		self.view = UIView(frame: overlayWindow.bounds)
		overlayWindow.rootViewController = self
		overlayWindow.makeKeyAndVisible()
		
		slider.frame = CGRect(x: 0, y: 0, width: overlayWindow.bounds.size.width, height: overlayWindow.bounds.size.height)
		slider.autoresizingMask = [.flexibleWidth]
		slider.addTarget(self, action: #selector(sliderAction(_:)), for: .valueChanged)
		slider.minimumValue = 0
		slider.maximumValue = 1
		slider.value = 1
		slider.isEnabled = false
		label.textAlignment = .center
		label.textColor = .white
		
		view.applyLayout(.vertical(marginEdges: .none,
			.interViewSpace,
			.horizontal(
				.space(20),
				.view(slider),
				.interViewSpace,
				.sizedView(label, .lengthGreaterThanOrEqualTo(constant: 50)),
				.space(20)
			),
			.interViewSpace
		))
		
		view.backgroundColor = UIColor(white: 0, alpha: 0.5)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		NotificationCenter.default.addObserver(self, selector: #selector(handleChangeNotification(_:)), name: Document.changedNotification, object: nil)
		updateDisplay()
	}
	
	@objc func handleChangeNotification(_ notification: Notification) {
		updateDisplay()
	}
	
	func updateDisplay() {
		let historyCount = Document.shared.history.count
		let historyIndex = (Document.shared.historyIndex ?? historyCount - 1) + 1
		label.text = "\(historyIndex)/\(historyCount)"
		
		slider.maximumValue = Float(historyCount)
		slider.minimumValue = 0 + (historyCount > 1 ? 1 : 0)
		slider.value = Float(historyIndex)
		slider.isEnabled = historyCount > 1
	}
	
	@objc func sliderAction(_ sender: Any?) {
		Document.shared.seek(Int(slider.value) - 1)
	}
}
