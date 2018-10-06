//
//  HistoryViewController.swift
//  Clocks
//
//  Created by Matt Gallagher on 2017/08/19.
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

import UIKit

class HistoryViewController: UIViewController {
	var overlayWindow: UIWindow
	var slider: UISlider
	var label: UILabel
	
	var documentHistory: [Data] = []
	var documentHistoryIndex: Int?
	
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
	
	func setWindowFrame() {
		let screenBounds = UIScreen.main.bounds
		let height: CGFloat = 16 + 40
		overlayWindow.frame = CGRect(x: screenBounds.origin.x, y: screenBounds.origin.y + screenBounds.size.height - height, width: screenBounds.size.width, height: height)
	}
	
	override func loadView() {
		setWindowFrame()
		overlayWindow.backgroundColor = .clear
		overlayWindow.isOpaque = false
		overlayWindow.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
		overlayWindow.rootViewController = self
		
		let view = UIView(frame: overlayWindow.bounds)
		
		slider.frame = CGRect(x: 0, y: 0, width: overlayWindow.bounds.size.width, height: 40)
		slider.autoresizingMask = [.flexibleWidth]
		slider.addTarget(self, action: #selector(sliderAction(_:)), for: .valueChanged)
		slider.minimumValue = 0
		slider.maximumValue = 1
		slider.value = 1
		slider.isEnabled = false
		
		label.textAlignment = .center
		label.textColor = .white
		
		view.backgroundColor = UIColor(white: 0, alpha: 0.5)
		
		self.view = view
		
		applyLayout()
		
		overlayWindow.makeKeyAndVisible()
	}
	
	func applyLayout() {
		setWindowFrame()
		view.applyLayout(.vertical(marginEdges: .none,
			.space(),
			.horizontal(
				.space(20),
				.view(slider),
				.space(),
				.view(length: .greaterThanOrEqualTo(constant: 50), label),
				.space(20)
			),
			.space()
		))
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		if let documentData = try? Document.shared.serialized() {
			documentHistory.append(documentData)
		}
		
		NotificationCenter.default.addObserver(self, selector: #selector(handleChangeNotification(_:)), name: nil, object: Document.shared)
		NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationChanged(_:)), name: UIDevice.orientationDidChangeNotification, object: nil)
		
		updateDisplay(userAction: false)
	}
	
	@objc func deviceOrientationChanged(_ notification: Notification) {
		setWindowFrame()
		view.frame = overlayWindow.bounds
	}
	
	@objc func handleChangeNotification(_ notification: Notification) {
		if notification.name == notifyingStoreReloadNotification {
			updateDisplay(userAction: false)
			return
		}
		
		let documentData = try? Document.shared.serialized()
		
		if let dd = documentData {
			if let truncateIndex = documentHistoryIndex, documentHistory.indices.contains(truncateIndex) {
				documentHistory.removeSubrange((truncateIndex + 1)..<documentHistory.endIndex)
			}
			documentHistory.append(dd)
			documentHistoryIndex = nil
		}
		
		updateDisplay(userAction: true)
	}
	
	func updateDisplay(userAction: Bool) {
		let hc = documentHistory.count
		let hi = (documentHistoryIndex ?? hc - 1) + 1
		label.text = "\(hi)/\(hc)"
		
		if userAction {
			slider.maximumValue = Float(hc)
			slider.minimumValue = 0 + (hc > 1 ? 1 : 0)
			if Int(round(slider.value)) - 1 != hi {
				slider.value = Float(hi)
			}
			slider.isEnabled = hc > 1
		}
	}
	
	@objc func sliderAction(_ sender: Any?) {
		if sender as? UISlider === slider {
			let hi = Int(round(slider.value)) - 1
			if documentHistoryIndex != hi, documentHistory.indices.contains(hi) {
				documentHistoryIndex = hi
				Document.shared.reloadAndNotify(jsonData: documentHistory[hi])
			}
		}
	}
}
