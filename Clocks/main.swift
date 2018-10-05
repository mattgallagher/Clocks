//
//  main.swift
//  Clocks
//
//  Created by Matt Gallagher on 2017/12/23.
//  Copyright © 2017 Matt Gallagher. All rights reserved.
//

import UIKit

private let doc = DocumentAdapter(document: Document())
private let viewState = Var(SplitState())

func application(_ viewState: Var<SplitState>, _ doc: DocumentAdapter) -> Application {
	return Application(
		.window -- Window(
			.rootViewController <-- viewState.map { split in
				splitViewController(split, doc)
			}
		),
		.additionalWindows -- [timeTravelWindow(doc, viewState)],
		.didEnterBackground --> Input().map { .save }.bind(to: doc),
		.willEncodeRestorableState -- { $0.encodeLatest(from: viewState) },
		.didDecodeRestorableState -- { $0.decodeSend(to: viewState) }
	)
}

applicationMain { application(viewState, doc) }
