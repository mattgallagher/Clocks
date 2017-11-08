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
	var secondSlider: UISlider
	var checkbox: UISwitch
	var label: UILabel
	var secondLabel: UILabel
	
	var documentHistory: [Data] = []
	var documentHistoryIndex: Int?
	var viewStateHistory: [Data] = []
	var viewStateHistoryIndex: Int?
	
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		overlayWindow = UIWindow()
		slider = UISlider()
		secondSlider = UISlider()
		checkbox = UISwitch()
		label = UILabel()
		secondLabel = UILabel()
		
		super.init(nibName: nil, bundle: nil)
		
		// Force a view load
		_ = self.view
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func setWindowFrame(twoSliders: Bool) {
		let screenBounds = UIScreen.main.bounds
		let height: CGFloat = 16 + (twoSliders ? 2 : 1) * 40
		overlayWindow.frame = CGRect(x: screenBounds.origin.x, y: screenBounds.origin.y + screenBounds.size.height - height, width: screenBounds.size.width, height: height)
	}
	
	override func loadView() {
		setWindowFrame(twoSliders: false)
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
		
		secondSlider.frame = CGRect(x: 0, y: 0, width: overlayWindow.bounds.size.width, height: 40)
		secondSlider.autoresizingMask = [.flexibleWidth]
		secondSlider.addTarget(self, action: #selector(sliderAction(_:)), for: .valueChanged)
		secondSlider.minimumValue = 0
		secondSlider.maximumValue = 1
		secondSlider.value = 1
		secondSlider.isEnabled = false
		
		label.textAlignment = .center
		label.textColor = .white
		secondLabel.textAlignment = .center
		secondLabel.textColor = .white
		
		checkbox.addTarget(self, action: #selector(toggleUnified(_:)), for: .valueChanged)
		checkbox.isOn = false
		
		view.backgroundColor = UIColor(white: 0, alpha: 0.5)

		self.view = view
		
		applyLayout(bothSliders: false)
		
		overlayWindow.makeKeyAndVisible()
	}
	
	func applyLayout(bothSliders: Bool) {
		setWindowFrame(twoSliders: bothSliders)
		if !bothSliders {
			view.applyLayout(.vertical(marginEdges: .none,
				.interViewSpace,
				.horizontal(
					.space(20),
					.view(checkbox),
					.interViewSpace,
					.view(slider),
					.interViewSpace,
					.sizedView(label, .lengthGreaterThanOrEqualTo(constant: 50)),
					.space(20)
				),
				.interViewSpace
			))
		} else {
			view.applyLayout(.vertical(
				marginEdges: .none,
				.interViewSpace,
				.horizontal(
					align: .center,
					.space(20),
					.view(checkbox),
					.interViewSpace,
					.vertical(
						.horizontal(.view(secondSlider), .interViewSpace, .sizedView(secondLabel, .lengthGreaterThanOrEqualTo(constant: 50))),
						.interViewSpace,
						.horizontal(.view(slider), .interViewSpace, .sizedView(label, .lengthGreaterThanOrEqualTo(constant: 50)))
					),
					.space(20)
				),
				.interViewSpace
			))
		}
	}
	
	@objc func toggleUnified(_ sender: Any?) {
		if let checkbox = sender as? UISwitch {
			applyLayout(bothSliders: checkbox.isOn)
		}
		if !checkbox.isOn {
			if documentHistory.count > viewStateHistory.count {
				documentHistory.removeSubrange(viewStateHistory.count..<documentHistory.count)
			} else if viewStateHistory.count > documentHistory.count {
				viewStateHistory.removeSubrange(documentHistory.count..<viewStateHistory.count)
			}
			viewStateHistoryIndex = nil
			documentHistoryIndex = nil
			Document.shared.reloadAndNotify(jsonData: documentHistory[documentHistory.count - 1])
			ViewState.shared.reloadAndNotify(jsonData: viewStateHistory[viewStateHistory.count - 1])
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		if let documentData = try? Document.shared.serialized() {
			documentHistory.append(documentData)
		}
		if let viewStateData = try? ViewState.shared.serialized() {
			viewStateHistory.append(viewStateData)
		}
		
		NotificationCenter.default.addObserver(self, selector: #selector(handleChangeNotification(_:)), name: nil, object: Document.shared)
		NotificationCenter.default.addObserver(self, selector: #selector(handleChangeNotification(_:)), name: nil, object: ViewState.shared)
		NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationChanged(_:)), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)

		updateDisplay(userAction: false)
	}
	
	@objc func deviceOrientationChanged(_ notification: Notification) {
		setWindowFrame(twoSliders: checkbox.isOn)
		view.frame = overlayWindow.bounds
	}
	
	@objc func handleChangeNotification(_ notification: Notification) {
		if notification.name == notifyingStoreReloadNotification {
			updateDisplay(userAction: false)
			return
		}

		let documentData = try? Document.shared.serialized()
		let viewStateData = try? ViewState.shared.serialized()

		if let dd = documentData, let vsd = viewStateData {
			if let truncateIndex = documentHistoryIndex, documentHistory.indices.contains(truncateIndex) {
				documentHistory.removeSubrange((truncateIndex + 1)..<documentHistory.endIndex)
			}
			documentHistory.append(dd)
			documentHistoryIndex = nil
			
			if let truncateIndex = viewStateHistoryIndex, viewStateHistory.indices.contains(truncateIndex) {
				viewStateHistory.removeSubrange((truncateIndex + 1)..<viewStateHistory.endIndex)
			}
			viewStateHistory.append(vsd)
			viewStateHistoryIndex = nil
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
		
		let vshc = viewStateHistory.count
		let vshi = (viewStateHistoryIndex ?? vshc - 1) + 1
		secondLabel.text = "\(vshi)/\(vshc)"
		
		if userAction {
			secondSlider.maximumValue = Float(vshc)
			secondSlider.minimumValue = 0 + (vshc > 1 ? 1 : 0)
			if Int(round(secondSlider.value)) - 1 != vshi {
				secondSlider.value = Float(vshi)
			}
			secondSlider.isEnabled = vshc > 1
		}
	}
	
	@objc func sliderAction(_ sender: Any?) {
		if sender as? UISlider === slider {
			let hi = Int(round(slider.value)) - 1
			if documentHistoryIndex != hi, documentHistory.indices.contains(hi) {
				documentHistoryIndex = hi
				Document.shared.loadWithoutNotifying(jsonData: documentHistory[hi])
				if !checkbox.isOn {
					viewStateHistoryIndex = hi
					ViewState.shared.loadWithoutNotifying(jsonData: viewStateHistory[hi])
				}
				Document.shared.postReloadNotification(jsonData: documentHistory[hi])
				if !checkbox.isOn {
					ViewState.shared.postReloadNotification(jsonData: viewStateHistory[hi])
				}
			}
		} else {
			let hi = Int(round(secondSlider.value)) - 1
			if viewStateHistoryIndex != hi, viewStateHistory.indices.contains(hi) {
				viewStateHistoryIndex = hi
				ViewState.shared.reloadAndNotify(jsonData: viewStateHistory[hi])
			}
		}
	}
}
