//
//  CwlLayout.swift
//  CwlViews
//
//  Created by Matt Gallagher on 2017/05/20.
//  Copyright © 2017 Matt Gallagher ( https://www.cocoawithlove.com ). All rights reserved.
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

#if os(macOS)
	import AppKit
	
	public protocol ViewConvertible {
		func nsView() -> Layout.View
	}
	extension Layout.View: ViewConvertible {
		public func nsView() -> Layout.View {
			return self
		}
	}
#else
	import UIKit
	
	public protocol ViewConvertible {
		func uiView() -> Layout.View
	}
	extension Layout.View: ViewConvertible {
		public func uiView() -> Layout.View {
			return self
		}
	}
#endif

/// When a layout is applied, it can animate one of three ways:
///
/// - none: do not animate to the new layout
/// - all: animate to the new layout
/// - subsequent: animate to the new layout only if there was a previous layout
public enum AnimationChoice {
	case none
	case all
	case subsequent
}

// This type handles a combination of `layoutMargin` and `safeAreaMargin` inset edges. If a `safeArea` edge is specified, it will be used instead of `layout` edge.
public struct MarginEdges: OptionSet {
	public static var none: MarginEdges { return MarginEdges(rawValue: 0) }
	public static var topLayout: MarginEdges { return MarginEdges(rawValue: 1) }
	public static var leadingLayout: MarginEdges { return MarginEdges(rawValue: 2) }
	public static var bottomLayout: MarginEdges { return MarginEdges(rawValue: 4) }
	public static var trailingLayout: MarginEdges { return MarginEdges(rawValue: 8) }
	public static var topSafeArea: MarginEdges { return MarginEdges(rawValue: 16) }
	public static var leadingSafeArea: MarginEdges { return MarginEdges(rawValue: 32) }
	public static var bottomSafeArea: MarginEdges { return MarginEdges(rawValue: 64) }
	public static var trailingSafeArea: MarginEdges { return MarginEdges(rawValue: 128) }
	public static var allLayout: MarginEdges { return [.topLayout, .leadingLayout, .bottomLayout, .trailingLayout] }
	public static var allSafeArea: MarginEdges { return [.topSafeArea, .leadingSafeArea, .bottomSafeArea, .trailingSafeArea] }
	public let rawValue: UInt
	public init(rawValue: UInt) {
		self.rawValue = rawValue
	}
}

#if os(macOS)
	extension NSView {
		/// Adds the views contained by `layout` in the arrangment described by the layout to `self`.
		///
		/// - Parameter layout: a set of views and layout descriptions
		public func applyLayout(_ layout: Layout?) {
			applyLayoutToView(view: self, params: layout.map { (layout: $0, bounds: Layout.Bounds(view: self, marginEdges: .none)) })
		}
	}
#else
	extension UIView {
		/// Adds the views contained by `layout` in the arrangment described by the layout to `self`.
		///
		/// - Parameter layout: a set of views and layout descriptions
		public func applyLayout(_ layout: Layout?) {
			applyLayoutToView(view: self, params: layout.map { (layout: $0, bounds: Layout.Bounds(view: self, marginEdges: $0.marginEdges)) })
		}
	}
	
	extension UIScrollView {
		/// Adds the views contained by `layout` in the arrangment described by the layout to `self`.
		///
		/// - Parameter layout: a set of views and layout descriptions
		public func applyContentLayout(_ layout: Layout?) {
			applyLayoutToView(view: self, params: layout.map { (layout: $0, bounds: Layout.Bounds(scrollView: self)) })
		}
	}
#endif

/// A data structure for describing a layout as a series of nested columns and rows.
public struct Layout {
	/// A rough equivalent to UIStackViewAlignment, minus baseline cases which aren't handled
	public enum Alignment { case leading, trailing, center, fill }
	
	#if os(macOS)
		public typealias Axis = NSUserInterfaceLayoutOrientation
		public typealias View = NSView
		public typealias Guide = NSLayoutGuide
	#else
		public typealias Axis = NSLayoutConstraint.Axis
		public typealias View = UIView
		public typealias Guide = UILayoutGuide
	#endif
	
	/// Layout is either horizontal or vertical (although any element within the layout may be a layout in the perpendicular direction)
	public let axis: Axis
	
	/// Within the horizontal row or vertical column, layout entities may fill, center or align-leading or align-trailing
	public let align: Alignment
	
	/// The layout may extend to the view bounds or may be limited by the safeAreaMargins or layoutMargins. The safeArea insets supercede the layoutMargins (prior to iOS 11, safeArea is interpreted as UIViewController top/bottom layout guides when laying out within a UIViewController, otherwise it is treated as a synonym for the layoutMargins). This value has no effect on macOS.	
	public let marginEdges: MarginEdges
	
	/// When applied to the top level `Layout` passed to 'applyLayout`, then replacing an existing layout on a view, if this variable is true, after applying the new layout, `layoutIfNeeded` will be called inside a `UIView.beginAnimations`/`UIView.endAnimations` block. Has no effect when set on a child `Layout`.
	public let animate: AnimationChoice
	
	/// This is the list of views, spaces and sublayouts that will be layed out.
	public var entities: [Entity]
	
	/// The default constructor assigns all values. In general, it's easier to use the `.horizontal` or `.vertical` constructor where possible.
	public init(axis: Axis, align: Alignment = .fill, marginEdges: MarginEdges = .allSafeArea, animate: AnimationChoice = .subsequent, entities: [Entity]) {
		self.axis = axis
		self.align = align
		self.entities = entities
		self.marginEdges = marginEdges
		self.animate = animate
	}
	
	/// A convenience constructor for a horizontal layout
	public static func horizontal(align: Alignment = .fill, marginEdges: MarginEdges = .allSafeArea, animate: AnimationChoice = .subsequent, _ entities: Entity...) -> Layout {
		return Layout(axis: .horizontal, align: align, marginEdges: marginEdges, animate: animate, entities: entities)
	}
	
	/// A convenience constructor for a vertical layout
	public static func vertical(align: Alignment = .fill, marginEdges: MarginEdges = .allSafeArea, animate: AnimationChoice = .subsequent, _ entities: Entity...) -> Layout {
		return Layout(axis: .vertical, align: align, marginEdges: marginEdges, animate: animate, entities: entities)
	}
	
	/// A convenience constructor for a vertical layout
	public static func single(align: Alignment = .fill, marginEdges: MarginEdges = .allSafeArea, animate: AnimationChoice = .subsequent, length: Dimension? = nil, breadth: Dimension? = nil, relative: Bool = false, _ view: ViewConvertible) -> Layout {
		return Layout(axis: .vertical, align: align, marginEdges: marginEdges, animate: animate, entities: [Entity.view(length: length, breadth: breadth, relative: relative, view)])
	}
	
	// Used for removing all views from their superviews
	fileprivate func forEachView(_ visit: (View) -> Void) {
		entities.forEach { $0.forEachView(visit) }
	}

	/// The `Layout` describes a series of these `Entity`s which may be a space, a view or a sublayout. There is also a special `matched` layout which allows a series of "same length" entities.
	///
	/// - interViewSpace: AppKit and UIKit use an 8 screen unit space as the "standard" space between adjacent views.
	/// - space: an arbitrary space between views
	/// - view: a view with optional width and height (if not specified, the view will use its "intrinsic" size or will fill the available layout space)
	/// - layout: a nested layout which may be parallel or perpedicular to its container and whose size may be specified (like view)
	/// - matched: a sequence of alternating "same size" and independent entities (you can use `.space(0)` if you don't want independent entities).
	public struct Entity {
		public enum Content {
			case space(Dimension)
			case sizedView(Layout.View, Size?)
			indirect case layout(Layout, size: Size?)
			indirect case matched(Matched)
		}
		public let content: Content
		public init(_ content: Content) {
			self.content = content
		}
		
		fileprivate func forEachView(_ visit: (Layout.View) -> Void) {
			switch content {
			case .sizedView(let v, _):
				#if os(macOS)
					visit(v.nsView())
				#else
					visit(v.uiView())
				#endif
			case .layout(let l, _): l.forEachView(visit)
			case .matched(let matched):
				matched.first.forEachView(visit)
				matched.subsequent.forEach { element in
					switch element {
					case .free(let entity): entity.forEachView(visit)
					case .dependent(let dependent): dependent.entity.forEachView(visit)
					}
				}
			default: break
			}
		}
		
		public static func space(_ dimension: Dimension = .standardSpace) -> Entity {
			return Entity(.space(dimension))
		}
		
		public static func view(length: Dimension? = nil, breadth: Dimension? = nil, relative: Bool = false, _ view: ViewConvertible) -> Entity {
			let size = Size(length: length, breadth: breadth, relative: relative)
			#if os(macOS)
				return Entity(.sizedView(view.nsView(), size))
			#else
				return Entity(.sizedView(view.uiView(), size))
			#endif
		}
		
		public static func horizontal(align: Alignment = .fill, length: Dimension? = nil, breadth: Dimension? = nil, relative: Bool = false, _ entities: Entity...) -> Entity {
			let size = Size(length: length, breadth: breadth, relative: relative)
			return Entity(.layout(Layout(axis: .horizontal, align: align, marginEdges: .none, entities: entities), size: size))
		}
		
		public static func vertical(align: Alignment = .fill, length: Dimension? = nil, breadth: Dimension? = nil, relative: Bool = false, _ entities: Entity...) -> Entity {
			let size = Size(length: length, breadth: breadth, relative: relative)
			return Entity(.layout(Layout(axis: .vertical, align: align, marginEdges: .none, entities: entities), size: size))
		}
		
		public static func matchedPair(_ left: Entity, _ right: Entity, separator: Entity = .space(), priority: Dimension.Priority = .required) -> Entity {
			return Entity(.matched(Matched(
				first: left,
				subsequent: [
					.free(separator),
					.dependent(.init(entity: right, dimension: .equalTo(ratio: 1.0, priority: priority)))
				]
			)))
		}
		
		public static func matched(_ first: Entity, _ subsequent: [Matched.Element]) -> Entity {
			return Entity(.matched(.init(first: first, subsequent: subsequent)))
		}
	}
	
	/// A `Matched` element in a layout is a first element, followed by an array of free and dependent elements. The dependent elements all have a dimension  relationship to the first element (e.g. same size).
	public struct Matched {
		public struct Dependent {
			public let entity: Entity
			public let dimension: Dimension
			public init(entity: Entity, dimension: Dimension) {
				self.entity = entity
				self.dimension = dimension
			}
		}
		public enum Element {
			case dependent(Dependent)
			case free(Entity)
		}
		public let first: Entity
		public let subsequent: [Element]
		public init(first: Entity, subsequent: [Element]) {
			self.first = first
			self.subsequent = subsequent
		}
	}

	/// A `Size` is the combination of both length (size of a layout object in the direction of layout) or breadth (size of a layout object perpendicular to the layout direction). If the length includes a ratio, it is relative to the parent container but the breadth can be relative to the length, allowing for specifying an aspect ratio.
	public struct Size {
		public let length: Dimension?
		public let breadth: Dimension?
		public let relative: Bool
		
		public init(length: Dimension? = nil, breadth: Dimension?, relative: Bool = false) {
			self.length = length
			self.breadth = breadth
			self.relative = relative
		}
	}

	/// When length (size of a layout object in the direction of layout) or breadth (size of a layout object perpendicular to the layout direction) is specified, it can be specified:
	///	* relative to the parent container (ratio)
	///	* in raw screen units (constant)
	/// The greater/less than and priority can also be specified.
	public struct Dimension: ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
		public typealias FloatLiteralType = Double
		public typealias IntegerLiteralType = Int
		
		#if os(macOS)
			public typealias Relation = NSLayoutConstraint.Relation
			public typealias Priority = NSLayoutConstraint.Priority
		#else
			public typealias Relation = NSLayoutConstraint.Relation
			public typealias Priority = UILayoutPriority
		#endif
		
		public let ratio: CGFloat
		public let constant: CGFloat
		public let relationship: Relation
		public let priority: Dimension.Priority
		public init(ratio: CGFloat = 0, constant: CGFloat = 0, relationship: Dimension.Relation = .equal, priority: Dimension.Priority = .required) {
			self.ratio = ratio
			self.constant = constant
			self.relationship = relationship
			self.priority = priority
		}
		
		public init(floatLiteral value: Double) {
			self.init(constant: CGFloat(value))
		}
		
		public init(integerLiteral value: Int) {
			self.init(constant: CGFloat(value))
		}
		
		public static var standardSpace: Dimension = 8
		
		public static func lessThanOrEqualTo(ratio: CGFloat = 0, constant: CGFloat = 0, priority: Dimension.Priority = .required) -> Dimension {
			return Dimension(ratio: ratio, constant: constant, relationship: .lessThanOrEqual, priority: priority)
		}
		
		public static func greaterThanOrEqualTo(ratio: CGFloat = 0, constant: CGFloat = 0, priority: Dimension.Priority = .required) -> Dimension {
			return Dimension(ratio: ratio, constant: constant, relationship: .greaterThanOrEqual, priority: priority)
		}
		
		public static func equalTo(ratio: CGFloat = 0, constant: CGFloat = 0, priority: Dimension.Priority = .required) -> Dimension {
			return Dimension(ratio: ratio, constant: constant, relationship: .equal, priority: priority)
		}
		
		public static var fillRemaining: Dimension {
			return equalTo(ratio: 1, priority: .userMid)
		}
		
		fileprivate func scaledConstraintBetween(first: NSLayoutDimension, second: NSLayoutDimension, constraints: inout [NSLayoutConstraint]) {
			let constraint: NSLayoutConstraint
			switch relationship {
			case .equal: constraint = first.constraint(equalTo: second, multiplier: ratio, constant: constant)
			case .lessThanOrEqual: constraint = first.constraint(lessThanOrEqualTo: second, multiplier: ratio, constant: constant)
			case .greaterThanOrEqual: constraint = first.constraint(greaterThanOrEqualTo: second, multiplier: ratio, constant: constant)
			}
			constraint.priority = priority
			constraints.append(constraint)
			constraint.isActive = true
		}
		
		fileprivate func unscaledConstraintBetween<AnchorType>(first: NSLayoutAnchor<AnchorType>, second: NSLayoutAnchor<AnchorType>, constraints: inout [NSLayoutConstraint], reverse: Bool = false) {
			let constraint: NSLayoutConstraint
			switch (relationship, reverse) {
			case (.equal, _): constraint = first.constraint(equalTo: second, constant: reverse ? -constant: constant)
			case (.lessThanOrEqual, false), (.greaterThanOrEqual, true): constraint = first.constraint(lessThanOrEqualTo: second, constant: reverse ? -constant: constant)
			case (.greaterThanOrEqual, false), (.lessThanOrEqual, true): constraint = first.constraint(greaterThanOrEqualTo: second, constant: reverse ? -constant: constant)
			}
			constraint.priority = priority
			constraints.append(constraint)
			constraint.isActive = true
		}
	}

	/// Bounds are used internally to capture a set of guides and anchors. On the Mac, these are merely copied from a single NSLayoutGuide or an NSView. On iOS, these may be copied from a blend of UIViewController top/bottomLayoutGuides, safeAreaLayoutGuides, layoutMarginsGuides or a UIView.
	fileprivate struct Bounds {
		var leading: NSLayoutXAxisAnchor
		var top: NSLayoutYAxisAnchor
		var trailing: NSLayoutXAxisAnchor
		var bottom: NSLayoutYAxisAnchor
		var width: NSLayoutDimension
		var height: NSLayoutDimension
		var centerX: NSLayoutXAxisAnchor
		var centerY: NSLayoutYAxisAnchor
		
		fileprivate init(box: Layout.Box) {
			leading = box.leadingAnchor
			top = box.topAnchor
			trailing = box.trailingAnchor
			bottom = box.bottomAnchor
			width = box.widthAnchor
			height = box.heightAnchor
			centerX = box.centerXAnchor
			centerY = box.centerYAnchor
		}
		
		#if os(iOS)
			fileprivate init(scrollView: UIScrollView) {
				leading = scrollView.contentLayoutGuide.leadingAnchor
				top = scrollView.contentLayoutGuide.topAnchor
				trailing = scrollView.contentLayoutGuide.trailingAnchor
				bottom = scrollView.contentLayoutGuide.bottomAnchor
				width = scrollView.contentLayoutGuide.widthAnchor
				height = scrollView.contentLayoutGuide.heightAnchor
				centerX = scrollView.contentLayoutGuide.centerXAnchor
				centerY = scrollView.contentLayoutGuide.centerYAnchor
			}
			
			fileprivate init(view: Layout.View, marginEdges: MarginEdges) {
				leading = marginEdges.contains(.leadingSafeArea) ? view.safeAreaLayoutGuide.leadingAnchor : (marginEdges.contains(.leadingLayout) ? view.layoutMarginsGuide.leadingAnchor : view.leadingAnchor)
				top = marginEdges.contains(.topSafeArea) ? view.safeAreaLayoutGuide.topAnchor : (marginEdges.contains(.topLayout) ? view.layoutMarginsGuide.topAnchor : view.topAnchor)
				trailing = marginEdges.contains(.trailingSafeArea) ? view.safeAreaLayoutGuide.trailingAnchor : (marginEdges.contains(.trailingLayout) ? view.layoutMarginsGuide.trailingAnchor : view.trailingAnchor)
				bottom = marginEdges.contains(.bottomSafeArea) ? view.safeAreaLayoutGuide.bottomAnchor : (marginEdges.contains(.bottomLayout) ? view.layoutMarginsGuide.bottomAnchor : view.bottomAnchor)
				width = (marginEdges.contains(.leadingSafeArea) && marginEdges.contains(.trailingSafeArea)) ? view.safeAreaLayoutGuide.widthAnchor : (marginEdges.contains(.leadingLayout) && marginEdges.contains(.trailingLayout) ? view.layoutMarginsGuide.widthAnchor : view.widthAnchor)
				height = (marginEdges.contains(.leadingSafeArea) && marginEdges.contains(.trailingSafeArea)) ? view.safeAreaLayoutGuide.heightAnchor : (marginEdges.contains(.leadingLayout) && marginEdges.contains(.trailingLayout) ? view.layoutMarginsGuide.heightAnchor : view.heightAnchor)
				centerX = (marginEdges.contains(.leadingSafeArea) && marginEdges.contains(.trailingSafeArea)) ? view.safeAreaLayoutGuide.centerXAnchor : (marginEdges.contains(.leadingLayout) && marginEdges.contains(.trailingLayout) ? view.layoutMarginsGuide.centerXAnchor : view.centerXAnchor)
				centerY = (marginEdges.contains(.leadingSafeArea) && marginEdges.contains(.trailingSafeArea)) ? view.safeAreaLayoutGuide.centerYAnchor : (marginEdges.contains(.leadingLayout) && marginEdges.contains(.trailingLayout) ? view.layoutMarginsGuide.centerYAnchor : view.centerYAnchor)
			}
		#else
			fileprivate init(view: Layout.View, marginEdges: MarginEdges) {
				leading = view.leadingAnchor
				top = view.topAnchor
				trailing = view.trailingAnchor
				bottom = view.bottomAnchor
				width = view.widthAnchor
				height = view.heightAnchor
				centerX = view.centerXAnchor
				centerY = view.centerYAnchor
			}
		#endif
	}

	fileprivate struct State {
		let view: View
		let storage: Storage
		
		var dimension: Dimension? = nil
		var previousEntityBounds: Bounds? = nil
		var containerBounds: Bounds
		
		init(containerBounds: Bounds, in view: View, storage: Storage) {
			self.containerBounds = containerBounds
			self.view = view
			self.storage = storage
		}
	}

	fileprivate class Storage: NSObject {
		let layout: Layout
		var constraints: [NSLayoutConstraint] = []
		var boxes: [Layout.Box] = []
		
		init(layout: Layout) {
			self.layout = layout
		}
	}

	fileprivate func twoPointConstraint<First, Second>(firstSource: NSLayoutAnchor<First>, firstTarget: NSLayoutAnchor<First>, secondSource: NSLayoutAnchor<Second>, secondTarget: NSLayoutAnchor<Second>, secondRelationLessThan: Bool? = nil, constraints: inout [NSLayoutConstraint]) {
		let first = firstSource.constraint(equalTo: firstTarget)
		first.priority = .required
		first.isActive = true
		constraints.append(first)
		
		let secondLow = secondSource.constraint(equalTo: secondTarget)
		
		var secondHigh: NSLayoutConstraint? = nil
		if secondRelationLessThan == true {
			secondHigh = secondSource.constraint(lessThanOrEqualTo: secondTarget)
		} else if secondRelationLessThan == false {
			secondHigh = secondSource.constraint(greaterThanOrEqualTo: secondTarget)
		}
		if let high = secondHigh {
			secondLow.priority = .userLow
			high.priority = .userHigh
			high.isActive = true
			constraints.append(high)
		} else {
			secondLow.priority = .userHigh
		}
		secondLow.isActive = true
		constraints.append(secondLow)
	}
	
	fileprivate func constrain(bounds: Bounds, leading: Dimension, length: Dimension?, breadth: Dimension?, relative: Bool, state: inout State) {
		switch axis {
		case .horizontal:
			leading.unscaledConstraintBetween(first: bounds.leading, second: state.containerBounds.leading, constraints: &state.storage.constraints)
			
			if let l = length {
				l.scaledConstraintBetween(first: bounds.width, second: state.containerBounds.width, constraints: &state.storage.constraints)
			}
			if let b = breadth {
				b.scaledConstraintBetween(first: bounds.height, second: relative ? bounds.width : state.containerBounds.height, constraints: &state.storage.constraints)
			}
			
			switch self.align {
			case .leading:
				twoPointConstraint(firstSource: bounds.top, firstTarget: state.containerBounds.top, secondSource: bounds.bottom, secondTarget: state.containerBounds.bottom, secondRelationLessThan: true, constraints: &state.storage.constraints)
			case .trailing:
				twoPointConstraint(firstSource: bounds.bottom, firstTarget: state.containerBounds.bottom, secondSource: bounds.top, secondTarget: state.containerBounds.top, secondRelationLessThan: false, constraints: &state.storage.constraints)
			case .center:
				twoPointConstraint(firstSource: bounds.centerY, firstTarget: state.containerBounds.centerY, secondSource: bounds.height, secondTarget: state.containerBounds.height, secondRelationLessThan: true, constraints: &state.storage.constraints)
			case .fill:
				twoPointConstraint(firstSource: bounds.top, firstTarget: state.containerBounds.top, secondSource: bounds.bottom, secondTarget: state.containerBounds.bottom, secondRelationLessThan: nil, constraints: &state.storage.constraints)
			}
			
			state.containerBounds.leading = bounds.trailing
		case .vertical:
			leading.unscaledConstraintBetween(first: bounds.top, second: state.containerBounds.top, constraints: &state.storage.constraints)
			
			if let l = length {
				l.scaledConstraintBetween(first: bounds.height, second: state.containerBounds.height, constraints: &state.storage.constraints)
			}
			
			if let b = breadth {
				b.scaledConstraintBetween(first: bounds.width, second: relative ? bounds.height : state.containerBounds.width, constraints: &state.storage.constraints)
			}
			
			switch self.align {
			case .leading:
				twoPointConstraint(firstSource: bounds.leading, firstTarget: state.containerBounds.leading, secondSource: bounds.trailing, secondTarget: state.containerBounds.trailing, secondRelationLessThan: true, constraints: &state.storage.constraints)
			case .trailing:
				twoPointConstraint(firstSource: bounds.trailing, firstTarget: state.containerBounds.trailing, secondSource: bounds.leading, secondTarget: state.containerBounds.leading, secondRelationLessThan: false, constraints: &state.storage.constraints)
			case .center:
				twoPointConstraint(firstSource: bounds.centerX, firstTarget: state.containerBounds.centerX, secondSource: bounds.width, secondTarget: state.containerBounds.width, secondRelationLessThan: true, constraints: &state.storage.constraints)
			case .fill:
				twoPointConstraint(firstSource: bounds.leading, firstTarget: state.containerBounds.leading, secondSource: bounds.trailing, secondTarget: state.containerBounds.trailing, secondRelationLessThan: nil, constraints: &state.storage.constraints)
			}
			
			state.containerBounds.top = bounds.bottom
		}
	}
	
	@discardableResult
	fileprivate func layout(entity: Entity, state: inout State, needDimensionAnchor: Bool = false) -> NSLayoutDimension? {
		switch entity.content {
		case .space(let dimension):
			if let d = state.dimension, (d.ratio != 0 || d.constant != 0) {
				let box = Layout.Box()
				state.view.addLayoutBox(box)
				state.storage.boxes.append(box)
				constrain(bounds: Bounds(box: box), leading: Dimension(), length: d, breadth: nil, relative: false, state: &state)
				state.previousEntityBounds = nil
			}
			if dimension.ratio != 0 || needDimensionAnchor {
				let box = Layout.Box()
				state.view.addLayoutBox(box)
				state.storage.boxes.append(box)
				constrain(bounds: Bounds(box: box), leading: Dimension(), length: dimension, breadth: nil, relative: false, state: &state)
				if !needDimensionAnchor {
					state.previousEntityBounds = Bounds(box: box)
				}
				return axis == .horizontal ? box.widthAnchor : box.heightAnchor
			}
			state.dimension = dimension
			return nil
		case .layout(let l, let size):
			let box = Layout.Box()
			state.view.addLayoutBox(box)
			state.storage.boxes.append(box)
			let bounds = Bounds(box: box)
			l.add(to: state.view, containerBounds: bounds, storage: state.storage)
			constrain(bounds: bounds, leading: state.dimension ?? Dimension(), length: size?.length, breadth: size?.breadth, relative: size?.relative ?? false, state: &state)
			state.dimension = nil
			state.previousEntityBounds = bounds
			return needDimensionAnchor ? (axis == .horizontal ? box.widthAnchor : box.heightAnchor) : nil
		case .matched(let matched):
			if needDimensionAnchor {
				let box = Layout.Box()
				state.view.addLayoutBox(box)
				state.storage.boxes.append(box)
				var subState = State(containerBounds: state.containerBounds, in: state.view, storage: state.storage)
				layout(entity: entity, state: &subState)
				state.dimension = nil
				state.previousEntityBounds = Bounds(box: box)
				return axis == .horizontal ? box.widthAnchor : box.heightAnchor
			} else {
				let first = layout(entity: matched.first, state: &state, needDimensionAnchor: true)!
				for element in matched.subsequent {
					switch element {
					case .free(let entity): layout(entity: entity, state: &state)
					case .dependent(let dependent):
						let match = layout(entity: dependent.entity, state: &state, needDimensionAnchor: true)!
						dependent.dimension.scaledConstraintBetween(first: match, second: first, constraints: &state.storage.constraints)
					}
				}
				return nil
			}
		case .sizedView(let v, let size):
			#if os(macOS)
				let view = v.nsView()
			#else
				let view = v.uiView()
			#endif
			view.translatesAutoresizingMaskIntoConstraints = false
			state.view.addSubview(view)
			constrain(bounds: Bounds(view: view, marginEdges: .none), leading: state.dimension ?? Dimension(), length: size?.length, breadth: size?.breadth, relative: size?.relative ?? false, state: &state)
			state.dimension = nil
			state.previousEntityBounds = Bounds(view: view, marginEdges: .none)
			return needDimensionAnchor ? (axis == .horizontal ? view.widthAnchor : view.heightAnchor) : nil
		}
	}
	
	fileprivate func add(to view: Layout.View, containerBounds: Bounds, storage: Storage) {
		var state = State(containerBounds: containerBounds, in: view, storage: storage)
		for entity in entities {
			layout(entity: entity, state: &state)
		}
		if let previous = state.previousEntityBounds {
			switch axis {
			case .horizontal:
				(state.dimension ?? Dimension()).unscaledConstraintBetween(first: previous.trailing, second: state.containerBounds.trailing, constraints: &state.storage.constraints, reverse: true)
			case .vertical:
				(state.dimension ?? Dimension()).unscaledConstraintBetween(first: previous.bottom, second: state.containerBounds.bottom, constraints: &state.storage.constraints, reverse: true)
			}
		}
	}
}

// DEBUGGING TIP:
// As of Xcode 8, the "Debug View Hierarchy" option does not show layout guides, making debugging of constraints involving layout guides tricky. To aid debugging in these cases, set the following condition to `true && DEBUG` and CwlLayout will create views instead of layout guides.
// Otherwise, you can set this to `false && DEBUG`.
#if true && DEBUG
extension Layout {
	fileprivate typealias Box = Layout.View
}
extension Layout.View {
	fileprivate func addLayoutBox(_ layoutBox: Layout.Box) {
		layoutBox.translatesAutoresizingMaskIntoConstraints = false
		self.addSubview(layoutBox)
	}
	fileprivate func removeLayoutBox(_ layoutBox: Layout.Box) {
		layoutBox.removeFromSuperview()
	}
}
#else
extension Layout {
	fileprivate typealias Box = Layout.Guide
}
extension Layout.View {
	fileprivate func addLayoutBox(_ layoutBox: Layout.Box) {
		self.addLayoutGuide(layoutBox)
	}
	fileprivate func removeLayoutBox(_ layoutBox: Layout.Box) {
		self.removeLayoutGuide(layoutBox)
	}
}
#endif

// NOTE:
//
// Views often have their own intrinsic size, and they maintain this size at
// either the `.defaultLow` or `.defaultHigh` priority. Unfortunately, layout
// doesn't work well if this intrinsic priority is perfectly balanced with the
// user-applied layout priority.
//
// For this reason, CwlLayout defaults to using the following layout priorities
// which are scaled to be slightly different to the default priorities. This
// allows you to easily set layout priorities above, between or below the
// intrinisic priorities without always resorting to `.required`.
//
extension Layout.Dimension.Priority {
	#if os(macOS)
		public static let userLow = NSLayoutConstraint.Priority(rawValue: 156.25)
		public static let userMid = NSLayoutConstraint.Priority(rawValue: 437.5)
		public static let userHigh = NSLayoutConstraint.Priority(rawValue: 843.75)
	#else
		public static let userLow = UILayoutPriority(rawValue: 156.25)
		public static let userMid = UILayoutPriority(rawValue: 437.5)
		public static let userHigh = UILayoutPriority(rawValue: 843.75)
	#endif
}

fileprivate var associatedLayoutKey = NSObject()
fileprivate func setLayout(_ newValue: Layout.Storage?, for object: Layout.View) {
	objc_setAssociatedObject(object, &associatedLayoutKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
}
fileprivate func getLayout(for view: Layout.View) -> Layout.Storage? {
	return objc_getAssociatedObject(view, &associatedLayoutKey) as? Layout.Storage
}

fileprivate extension Layout.View {
	func remove(constraintsAndBoxes previousLayout: Layout.Storage?, subviews: Set<Layout.View>) {
		guard let previous = previousLayout else { return }
		for constraint in previous.constraints {
			constraint.isActive = false
		}
		for box in previous.boxes {
			self.removeLayoutBox(box)
		}
		subviews.forEach { $0.removeFromSuperview() }
	}
}

fileprivate func applyLayoutToView(view: Layout.View, params: (layout: Layout, bounds: Layout.Bounds)?) {
	var removedViews = Set<Layout.View>()
	
	// Check for a previous layout and get the old views
	let previous = getLayout(for: view)
	previous?.layout.forEachView { view in removedViews.insert(view) }
	
	guard let (layout, bounds) = params else {
		// If there's no new layout, remove the old layout and we're done
		view.remove(constraintsAndBoxes: previous, subviews: removedViews)
		return
	}
	
	// Check if this will be animated
	let shouldAnimate = layout.animate != .none && (previous != nil || layout.animate != .subsequent)
	
	// Exclude views in the new layout from the removed set. If we're animating, we'll need animated and added sets too.
	var animatedViews = Set<Layout.View>()
	var addedViews = Set<Layout.View>()
	layout.forEachView { v in
		if let animated = removedViews.remove(v), shouldAnimate {
			animatedViews.insert(animated)
		} else if shouldAnimate {
			addedViews.insert(v)
		}
	}
	
	#if os(macOS)
		view.remove(constraintsAndBoxes: previous, subviews: removedViews)
		let storage = Layout.Storage(layout: layout)
		layout.add(to: view, containerBounds: bounds, storage: storage)
		setLayout(storage, for: view)
		return
	#else
		// Now that we know the precise removed set, remove them.
		if shouldAnimate && addedViews.count == 0 && removedViews.count > 0 {
			// If we're animating the removal of views but not the insertion of views, animate this removal
			UIView.transition(with: view, duration: 0.2, options: [.transitionCrossDissolve, .allowUserInteraction], animations: {
				view.remove(constraintsAndBoxes: previous, subviews: removedViews)
			}, completion: { completed in })
		} else {
			view.remove(constraintsAndBoxes: previous, subviews: removedViews)
		}
		
		// Apply the new layout
		let storage = Layout.Storage(layout: layout)
		layout.add(to: view, containerBounds: bounds, storage: storage)
		
		// If we're not animating, store the layout and we're done.
		if !shouldAnimate {
			setLayout(storage, for: view)
			return
		}
		
		if addedViews.count > 0 {
			// Apply the layout, so new views have a precise size
			view.layoutIfNeeded()
			
			// Remove the new views and revert to the old layout
			view.remove(constraintsAndBoxes: storage, subviews: addedViews)
			if let p = previous {
				let oldStorage = Layout.Storage(layout: layout)
				p.layout.add(to: view, containerBounds: bounds, storage: oldStorage)

				// Immediately remove the old constraints but keep the old views
				view.remove(constraintsAndBoxes: oldStorage, subviews: [])
			}
			
			// Animate the simultaneous removal and addition of new views
			UIView.transition(with: view, duration: 0.2, options: [.transitionCrossDissolve, .allowUserInteraction], animations: {
				removedViews.forEach { $0.removeFromSuperview() }
				addedViews.forEach { view.addSubview($0) }
			}, completion: { completed in })
			
			// Reapply the new layout. Since the new views are already in-place
			let reapplyStorage = Layout.Storage(layout: layout)
			layout.add(to: view, containerBounds: bounds, storage: reapplyStorage)
			setLayout(reapplyStorage, for: view)
		} else {
			setLayout(storage, for: view)
		}
		
		// Animate the frames of the new layout
		UIView.animate(withDuration: 0.2, delay: 0, options: [.allowUserInteraction], animations: {
			view.layoutIfNeeded()
		}, completion: { completed in })
	#endif
}
