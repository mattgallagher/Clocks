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

class SplitViewController: UISplitViewController, UISplitViewControllerDelegate, UINavigationControllerDelegate {
	
	var lastPresentedUuid: UUID?
	var masterViewController: MasterViewController?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		masterViewController = (viewControllers.first as? UINavigationController)?.topViewController as? MasterViewController
		
		self.preferredDisplayMode = .allVisible
		self.delegate = self
		(self.viewControllers.last as? UINavigationController)?.topViewController?.navigationItem.leftBarButtonItem = displayModeButtonItem
		(self.viewControllers.first as? UINavigationController)?.delegate = self
		
		NotificationCenter.default.addObserver(self, selector: #selector(handleChangeNotification(_:)), name: ViewState.changedNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleChangeNotification(_:)), name: Document.changedNotification, object: nil)
		lastPresentedUuid = ViewState.shared.splitView.detailView?.uuid
	}
	
	func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
		// The following logic aims to detect when a collapsed detail view is popped from the navigation stack
		if animated, navigationController.topViewController is MasterViewController, self.viewControllers.count == 1, ViewState.shared.splitView.detailView != nil {
			ViewState.shared.changeDetailSelection(uuid: nil)
		}
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
		
		// Both the selection view and the detail view have the potential to change whether the master view contorller is visible. We need to carefully ensure one transition completes before the other is handled – otherwise exceptions can occur.
		updateSelectionViewPresentation(isUserAction: isUserAction) {
			self.updateDetailViewPresentation(isUserAction: isUserAction)
		}
	}
	
	func updateSelectionViewPresentation(isUserAction: Bool, completion: (() -> Void)?) {
		let selectionView = ViewState.shared.splitView.selectionView
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
		let detailView = ViewState.shared.splitView.detailView
		if let uuid = detailView?.uuid, Document.shared.timezone(uuid) != nil, lastPresentedUuid != uuid {
			lastPresentedUuid = uuid
			masterViewController?.performSegue(withIdentifier: isUserAction ? "detail" : "detailWithoutAnimation", sender: self)
		} else if detailView.flatMap({ Document.shared.timezone($0.uuid) }) == nil, lastPresentedUuid != nil {
			lastPresentedUuid = nil
			if let masterNavigationController = viewControllers.first as? UINavigationController, masterNavigationController.topViewController is UINavigationController {
				masterNavigationController.popViewController(animated: isUserAction)
			}
		}
	}
	
	func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
		if ViewState.shared.splitView.detailView == nil {
			// Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
			return true
		}
		return false
	}
}
