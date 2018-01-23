//
//  ClocksTests.swift
//  ClocksTests
//
//  Created by Matt Gallagher on 2018/01/23.
//  Copyright © 2018 Matt Gallagher. All rights reserved.
//

import XCTest
import CwlViews
@testable import Clocks

class ClocksTests: XCTestCase {
    
	func testTableViewCellIdentifier() {
		// Create the inputs
		let select = SelectState()
		let split = SplitState()
		let doc = DocumentAdapter(document: Document())
		
		// Call our tableView function to create the view-binder then extract the bindings
		let bindings = selectTableView(select, split, doc).consumeBindings()
		
		// Select the binding we want
		var function: ((TableRowDescription<String>) -> String?)? = nil
		for b in bindings {
			if case .cellIdentifier(let f) = b {
				function = f
				break
			}
		}
		
		// Test the result
		let result = function?(TableRowDescription(indexPath: IndexPath(), rowData: nil))
		XCTAssert(result == "textRow")
	}
    
}
