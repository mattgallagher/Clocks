//
//  SplitViewController.swift
//  Clocks
//
//  Created by Matt Gallagher on 2017/08/21.
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

class SplitViewController: UISplitViewController, UISplitViewControllerDelegate {
	
	@IBOutlet var masterViewController: UINavigationController?
	@IBOutlet var detailViewController: UINavigationController?
	var lastPresentedUuid: UUID?
	
	// This is a more robust tracking of `isCollapsed`
	var needPopWhenClearing: Bool = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		detailViewController = viewControllers.last as? UINavigationController
		masterViewController = viewControllers.first as? UINavigationController
		
		// Override point for customization after application launch.
		self.preferredDisplayMode = .allVisible
		self.delegate = self
		detailViewController?.topViewController?.navigationItem.leftBarButtonItem = displayModeButtonItem
		
		NotificationCenter.default.addObserver(self, selector: #selector(handleChangeNotification(_:)), name: ViewState.changedNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleChangeNotification(_:)), name: Document.changedNotification, object: nil)
		lastPresentedUuid = ViewState.shared.topLevel.detailView?.uuid
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		// Need to reprocess view state here since this is the earliest that we could present the "selectTimezone" view controller
		updateSelectionViewPresentation(isUserAction: false, completion: nil)
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	@objc func handleChangeNotification(_ notification: Notification) {
		let isUserAction = notification.userActionData != nil
		
		updateSelectionViewPresentation(isUserAction: isUserAction) {
			self.updateDetailViewPresentation(isUserAction: isUserAction)
		}
	}
	
	func updateSelectionViewPresentation(isUserAction: Bool, completion: (() -> Void)?) {
		let selectionView = ViewState.shared.topLevel.selectionView
		if selectionView != nil, self.presentedViewController == nil, let selectTimezoneViewController = storyboard?.instantiateViewController(withIdentifier: "selectTimezone") {
			// If we're not present in the window, do nothing (assume the reprocess in `viewWillAppear` will catch anything relevant).
			if self.view.window != nil {
				self.present(selectTimezoneViewController, animated: isUserAction, completion: completion)
				return
			}
		} else if selectionView == nil, self.presentedViewController != nil {
			self.dismiss(animated: isUserAction, completion: completion)
			return
		}
		completion?()
	}
	
	func updateDetailViewPresentation(isUserAction: Bool) {
		// In the table view
		guard let dvc = detailViewController, let mvc = masterViewController else { return }
		let detailView = ViewState.shared.topLevel.detailView
		if let uuid = detailView?.uuid, Document.shared.timezones[uuid] != nil, lastPresentedUuid == nil {
			lastPresentedUuid = uuid
			
			// We're not allowed to re-show the detail view if it is already showing so guard against that
			// It might not be obvious why `self.view.window` is checked but on returning to the window, the `collapseSecondary` delegate function might re-present the detail view controller and we need to avoid illegally presenting the detail view twice.
			if self.view.window != nil, viewControllers.last != dvc, mvc.topViewController != dvc {
				if isUserAction {
					showDetailViewController(dvc, sender: mvc)
				} else {
					UIView.performWithoutAnimation {
						showDetailViewController(dvc, sender: nil)
					}
				}
			}
		} else if detailView.flatMap({ Document.shared.timezones[$0.uuid] }) == nil, lastPresentedUuid != nil {
			lastPresentedUuid = nil
			if needPopWhenClearing {
				if mvc.topViewController == dvc {
					mvc.popViewController(animated: isUserAction)
				}
				
				// This avoids an animation glitch where the second time the view controller is presented, it is presented at "navigation bar hidden" sizing before "popping" to "navigation bar visible" sizing.
				if let fvc = dvc.viewControllers.last {
					dvc.viewControllers.remove(at: dvc.viewControllers.count - 1)
					dvc.pushViewController(fvc, animated: false)
				}
			}
		}
	}
	
	func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
		detailViewController?.topViewController?.navigationItem.leftBarButtonItem = nil
		needPopWhenClearing = true
		if let detailView = ViewState.shared.topLevel.detailView {
			lastPresentedUuid = detailView.uuid
			return false
		} else {
			// Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
			return true
		}
	}
	
	func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
		needPopWhenClearing = false
		detailViewController?.topViewController?.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
		return nil
	}
}
