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
	var observations = [NSObjectProtocol]()
	var detailUuid: UUID?
	var masterNavigationController: UINavigationController? {
		return viewControllers.first as? UINavigationController
	}
	var masterViewController: MasterViewController? {
		return masterNavigationController?.topViewController as? MasterViewController
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.preferredDisplayMode = .allVisible
		self.delegate = self
		masterNavigationController?.delegate = self
		(self.viewControllers.last as? UINavigationController)?.topViewController?.navigationItem.leftBarButtonItem = displayModeButtonItem
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		// Must delay this to here since it is the earliest that `present` transitions can occur
		if observations.count == 0 {
			observations += CollectionOfOne(ViewState.shared.addObserver(actionType: SplitViewState.Action.self) { [weak self] state, action in
				self?.handleViewStateNotification(state: state, action: action)
			})
			observations += CollectionOfOne(Document.shared.addObserver(actionType: Document.Action.self) { [weak self] timezones, action in
				self?.handleDocumentNotification(timezones: timezones, action: action)
			})
		}
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func reloadDetailView(uuid: UUID?) {
		if uuid != detailUuid {
			if uuid != nil {
				masterViewController?.performSegue(withIdentifier: "detailWithoutAnimation", sender: self)
			} else {
				if masterNavigationController?.topViewController is UINavigationController {
					masterNavigationController?.popViewController(animated: false)
				}
			}
		}
	}
	
	func selectionViewController(show: Bool, animated: Bool, completion: (() -> ())?) {
		if show && presentedViewController == nil {
			let selectTimezoneViewController = storyboard!.instantiateViewController(withIdentifier: "selectTimezone")
			self.present(selectTimezoneViewController, animated: animated, completion: completion)
		} else if !show && presentedViewController != nil {
			self.dismiss(animated: animated, completion: completion)
		} else {
			completion?()
		}
	}
	
	func handleViewStateNotification(state: SplitViewState, action: SplitViewState.Action?) {
		switch action {
		case .changedDetail? where state.detailView != nil:
			masterViewController?.performSegue(withIdentifier: "detail", sender: self)
		case .changedDetail?:
			if masterNavigationController?.topViewController is UINavigationController {
				masterNavigationController?.popViewController(animated: true)
			}
		case .selectionViewVisibility?:
			selectionViewController(show: state.selectionView != nil, animated: true, completion: nil)
		case .none:
			selectionViewController(show: state.selectionView != nil, animated: false) {
				self.reloadDetailView(uuid: state.detailView?.uuid)
			}
		}
		detailUuid = state.detailView?.uuid
	}
	
	func handleDocumentNotification(timezones: Document.DataType, action: Document.Action?) {
		switch action {
		case .removed(let uuid)? where uuid == detailUuid:
			ViewState.shared.changeDetailSelection(uuid: nil)
		case .some: break
		case .none:
			if let uuid = detailUuid, timezones[uuid] == nil {
				ViewState.shared.changeDetailSelection(uuid: nil)
			}
		}
	}
	
	func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
		// The following logic aims to detect when a collapsed detail view is popped from the navigation stack
		if animated, !(masterNavigationController?.topViewController is UINavigationController), detailUuid != nil {
			ViewState.shared.changeDetailSelection(uuid: nil)
		}
	}
	
	func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
		if detailUuid == nil {
			// Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
			return true
		}
		return false
	}
}
