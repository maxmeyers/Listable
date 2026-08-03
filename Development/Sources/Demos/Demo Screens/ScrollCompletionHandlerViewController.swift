//
//  ScrollCompletionHandlerViewController.swift
//  Demo
//
//  Created by John Newman on 6/17/25.
//

import BlueprintUI
import BlueprintUICommonControls
import BlueprintUILists
import ListableUI
import UIKit


/// This demo superclass that is used to showcase the `scrollTo(...)` and `scollToSection(...)`
/// completion handlers. This allows you to demo how it executes in a number of layout situations.
/// This class should not be used directly. Instead, instantiate a subclass.
class ScrollCompletionHandlerViewController : UIViewController {
    
    fileprivate let list = ListView()
    
    fileprivate var sections: [Section] { [] }
    
    fileprivate var scrollAnimation: ScrollAnimation = .system

    fileprivate var scrollPosition: ScrollPosition.Position = .top
    
    fileprivate var ifAlreadyVisible: ScrollPosition.IfAlreadyVisible = .scrollToPosition
    
    private var layoutDirection : LayoutDirection = .vertical
    
    fileprivate lazy var scrollButton: UIBarButtonItem = {
        UIBarButtonItem(title: "Scroll", style: .plain, target: self, action: #selector(performScroll))
    }()
    
    fileprivate lazy var axisButton: UIBarButtonItem = {
        UIBarButtonItem(title: "Axis", style: .plain, target: self, action: #selector(toggleDirection))
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let stackView = UIStackView(arrangedSubviews: [list, settingsPanel])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 0
        view.addSubview(stackView)
        view.backgroundColor = .secondarySystemBackground
        NSLayoutConstraint.activate([
            view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: stackView.topAnchor),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
            view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: stackView.trailingAnchor)
        ])
        updateList()
    }

    private func updateList() {
        list.configure { list in
            list.appearance = .demoAppearance
            list.layout = .demoLayout { tableAppearance in
                tableAppearance.direction = self.layoutDirection
            }
            list.animation = .fast
            list += sections
        }
    }
    
    @objc fileprivate func performScroll() {
        assertionFailure("Override in subclasses.")
    }
    
    @objc func toggleDirection() {
        if layoutDirection == .horizontal {
            layoutDirection = .vertical
        } else {
            layoutDirection = .horizontal
        }
        updateList()
    }
    
    fileprivate var settingsControls: [UIView] {
        [selectionPanel, alreadyVisiblePanel, positionPanel, animationPanel]
    }
    
    /// This view contains all the configurable scroll settings.
    lazy var settingsPanel: UIView = {
        let stackView = UIStackView(
            arrangedSubviews: settingsControls
        )
        stackView.axis = .vertical
        stackView.spacing = 8
        let containerView = UIView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(stackView)
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 16),
            containerView.topAnchor.constraint(equalTo: stackView.topAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: stackView.bottomAnchor)
        ])
        return containerView
    }()
    
    /// The label and segmented control for selecting the scroll position.
    lazy var positionPanel: UIView = {
        let control = UISegmentedControl(
            items: [
                UIAction(title: "Top") { [weak self] _ in
                    self?.scrollPosition = .top
                },
                UIAction(title: "Centered") { [weak self] _ in
                    self?.scrollPosition = .centered
                },
                UIAction(title: "Bottom") { [weak self] _ in
                    self?.scrollPosition = .bottom
                }
            ]
        )
        control.selectedSegmentIndex = 0
        return titledView(control, title: "Position")
    }()
    
    /// The label and segmented control for selecting the behavior of an already-visible
    /// item
    lazy var alreadyVisiblePanel: UIView = {
        let control = UISegmentedControl(
            items: [
                UIAction(title: "Do nothing") { [weak self] _ in
                    self?.ifAlreadyVisible = .doNothing
                },
                UIAction(title: "Scroll to position") { [weak self] _ in
                    self?.ifAlreadyVisible = .scrollToPosition
                },
            ]
        )
        control.selectedSegmentIndex = 1
        return titledView(control, title: "If Visbile")
    }()
    
    /// The label and segmented control for selecting the scroll animation. The durations
    /// are deliberately slow enough to watch, since the point of `.duration` is to scroll
    /// at a speed the system animation does not offer.
    lazy var animationPanel: UIView = {
        let control = UISegmentedControl(
            items: [
                UIAction(title: "None") { [weak self] _ in
                    self?.scrollAnimation = .none
                },
                UIAction(title: "System") { [weak self] _ in
                    self?.scrollAnimation = .system
                },
                UIAction(title: "1s") { [weak self] _ in
                    self?.scrollAnimation = .duration(1)
                },
                UIAction(title: "3s") { [weak self] _ in
                    self?.scrollAnimation = .duration(3)
                },
            ]
        )
        control.selectedSegmentIndex = 1
        return titledView(control, title: "Animation")
    }()

    /// The label and segmented control for selecting the scrolled item/section.
    /// Override in subclasses.
    fileprivate var selectionPanel: UIView {
        assertionFailure("Override in subclasses.")
        return UIView()
    }
    
    /// Prints the items that were on screen when the scroll finished.
    fileprivate var printScrollCompletion: ListView.ScrollCompletion {
        { changes in
            let sortedItems = changes.positionInfo.visibleItems
                .map { "\($0.identifier) "}
                .sorted()
            print("Scroll completion: \(sortedItems)")
        }
    }

    /// A helper to add a label before `view`.
    fileprivate func titledView(_ view: UIView, title: String) -> UIView {
        let label = UILabel()
        label.text = title
        label.widthAnchor.constraint(equalToConstant: 125).isActive = true
        label.textAlignment = .right
        let stackView = UIStackView(arrangedSubviews: [label, view])
        stackView.axis = .horizontal
        stackView.spacing = 8
        return stackView
    }
}

/// A demo for showcasing scrolling to a particular item.
class ScrollToItemCompletionHandlerViewController: ScrollCompletionHandlerViewController {
    
    private lazy var items: [Item<SimpleScrollItem>] = {
        Array(0...100).map {
            Item(SimpleScrollItem(text: "Item \($0)"))
        }
    }()
    
    override var sections: [Section] {
        [Section("items", items: items)]
    }
    
    override var selectionPanel: UIView { itemSegmentedControl }
    
    private lazy var itemSegmentedControl: UIView = {
        let control = UISegmentedControl(
            items: [
                UIAction(title: "1") { [weak self] _ in
                    self?.scrolledItem = Item(SimpleScrollItem(text: "Item 1"))
                },
                UIAction(title: "50") { [weak self] _ in
                    self?.scrolledItem = Item(SimpleScrollItem(text: "Item 50"))
                },
                UIAction(title: "99") { [weak self] _ in
                    self?.scrolledItem = Item(SimpleScrollItem(text: "Item 99"))
                }
            ]
        )
        control.selectedSegmentIndex = 1
        return titledView(control, title: "Selection")
    }()
    
    private var scrolledItem = Item(SimpleScrollItem(text: "Item 50"))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // TODO: Fully add support for programmatic scrolling in horizontal layouts.
        // The axisButton is used in this demo because there are no section headers.
        navigationItem.rightBarButtonItems = [scrollButton, axisButton]
    }

    override func performScroll() {
        list.scrollTo(
            item: scrolledItem,
            position: ScrollPosition(
                position: scrollPosition,
                ifAlreadyVisible: ifAlreadyVisible
            ),
            animation: scrollAnimation,
            completion: printScrollCompletion
        )
    }
}

/// A demo for showcasing scrolling to a particular section.
class ScrollToSectionCompletionHandlerViewController: ScrollCompletionHandlerViewController {

    /// How many sections the list has. Subclasses can raise this to move the far sections
    /// out of the initially laid out content.
    fileprivate var sectionCount: Int { 3 }

    /// How many items each section has.
    fileprivate var itemsPerSection: Int { 101 }

    override var sections: [Section] { _sections }

    private lazy var _sections: [Section] = {
        (0..<sectionCount).map { sectionIndex in
            Section(
                "Section \(sectionIndex)",
                items: {
                    (0..<self.itemsPerSection).map { itemIndex in
                        Item(SimpleScrollItem(text: "Section \(sectionIndex) - Item \(itemIndex)"))
                    }
                },
                header: {
                    DemoHeader(title: "Section \(sectionIndex) Header")
                },
                footer: {
                    DemoFooter(text: "Section \(sectionIndex) Footer")
                }
            )
        }
    }()

    override var selectionPanel: UIView { sectionSegmentedControl }

    /// The first, middle and last sections, so that the control always offers a target
    /// beyond the initially laid out content.
    private var selectableSectionIndexes: [Int] {
        [0, sectionCount / 2, sectionCount - 1]
    }

    private lazy var sectionSegmentedControl: UIView = {
        let control = UISegmentedControl(
            items: selectableSectionIndexes.map { sectionIndex in
                UIAction(title: "\(sectionIndex)") { [weak self] _ in
                    self?.scrolledSection = Section.identifier(with: "Section \(sectionIndex)")
                }
            }
        )
        control.selectedSegmentIndex = 1
        return titledView(control, title: "Section")
    }()

    private var sectionPosition: SectionPosition = .top
    
    override var settingsControls: [UIView] {
        super.settingsControls + [sectionPositionControl]
    }
    
    /// The label and segmented control for selecting the section position, which powers
    /// whether the header or footer will be positioned.
    lazy var sectionPositionControl: UIView = {
        let control = UISegmentedControl(
            items: [
                UIAction(title: "Top/Header") { [weak self] _ in
                    self?.sectionPosition = .top
                },
                UIAction(title: "Bottom/Footer") { [weak self] _ in
                    self?.sectionPosition = .bottom
                },
            ]
        )
        control.selectedSegmentIndex = 0
        return titledView(control, title: "Supp. View")
    }()
    
    fileprivate lazy var scrolledSection: Section.Identifier = Section.identifier(
        with: "Section \(sectionCount / 2)"
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        // TODO: Fully add support for programmatic scrolling in horizontal layouts.
        // Until then, the axisButton is not used in this demo.
        navigationItem.rightBarButtonItems = [scrollButton]
    }

    override func performScroll() {
        list.scrollToSection(
            with: scrolledSection,
            sectionPosition: sectionPosition,
            scrollPosition: ScrollPosition(
                position: scrollPosition,
                ifAlreadyVisible: ifAlreadyVisible
            ),
            animation: scrollAnimation,
            completion: printScrollCompletion
        )
    }
}

/// A demo for showcasing scrolling to a section that is too far away to have been laid out
/// yet. The list defers the content offset change until its presentation state catches up
/// with the target, so this is the path where a requested animation is easiest to lose.
///
/// Pick a long `.duration` and the last section to see it: the scroll should ease all the way
/// there, rather than hard-jumping and then easing over the last screenful.
final class ScrollToOffscreenSectionCompletionHandlerViewController : ScrollToSectionCompletionHandlerViewController {

    /// Enough sections that the far ones are nowhere near the initially laid out content.
    override var sectionCount: Int { 40 }

    override var itemsPerSection: Int { 21 }
}

struct SimpleScrollItem : BlueprintItemContent, Equatable {
    var text : String

    var identifierValue: String {
        text
    }

    func element(with info : ApplyItemContentInfo) -> Element {
        Box(
            backgroundColor: .white,
            cornerStyle: .rounded(radius: 6.0),
            borderStyle: .solid(color: .white(0.9), width: 2.0),
            wrapping: Inset(
                uniformInset: 10.0,
                wrapping: Label(text: self.text)
            )
        )
    }
}
