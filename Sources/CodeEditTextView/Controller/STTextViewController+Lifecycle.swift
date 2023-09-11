//
//  STTextViewController+Lifecycle.swift
//  CodeEditTextView
//
//  Created by Khan Winter on 5/3/23.
//

import AppKit
import STTextView

extension STTextViewController {
//    override public func loadView() {
//        textView = CETextView()
//
//        let scrollView = CEScrollView()
//        scrollView.translatesAutoresizingMaskIntoConstraints = false
//        scrollView.hasVerticalScroller = true
//        scrollView.documentView = textView
//        scrollView.automaticallyAdjustsContentInsets = contentInsets == nil
//
//        rulerView = STLineNumberRulerView(textView: textView, scrollView: scrollView)
//        rulerView.drawSeparator = false
//        rulerView.baselineOffset = baselineOffset
//        rulerView.allowsMarkers = false
//        rulerView.backgroundColor = theme.background
//        rulerView.textColor = .secondaryLabelColor
//
//        scrollView.verticalRulerView = rulerView
//        scrollView.rulersVisible = true
//
//        textView.typingAttributes = attributesFor(nil)
//        textView.typingAttributes[.paragraphStyle] = self.paragraphStyle
//        textView.font = self.font
//        textView.insertionPointWidth = 1.0
//        textView.backgroundColor = .clear
//
//        textView.string = self.text.wrappedValue
//        textView.allowsUndo = true
//        textView.setupMenus()
//        textView.delegate = self
//
//        scrollView.documentView = textView
//        scrollView.translatesAutoresizingMaskIntoConstraints = false
//        scrollView.backgroundColor = useThemeBackground ? theme.background : .clear
//
//        self.view = scrollView
//
//        NSLayoutConstraint.activate([
//            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
//            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
//        ])
//
//        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
//            self.keyDown(with: event)
//            return event
//        }
//
////        textViewUndoManager = CEUndoManager(textView: textView)
//        reloadUI()
//        setUpHighlighter()
//        setHighlightProvider(self.highlightProvider)
//        setUpTextFormation()
//
//        self.setCursorPosition(self.cursorPosition.wrappedValue)
//    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(forName: NSWindow.didResizeNotification,
                                               object: nil,
                                               queue: .main) { [weak self] _ in
            guard let self = self else { return }
            (self.view as? NSScrollView)?.contentView.contentInsets.bottom = self.bottomContentInsets
            self.updateTextContainerWidthIfNeeded()
        }

        NotificationCenter.default.addObserver(
            forName: STTextView.didChangeSelectionNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            let textSelections = self?.textView.textLayoutManager.textSelections.flatMap(\.textRanges)
            guard self?.lastTextSelections != textSelections else {
                return
            }
            self?.lastTextSelections = textSelections ?? []

            self?.updateCursorPosition()
            self?.highlightSelectionPairs()
        }

        NotificationCenter.default.addObserver(
            forName: NSView.frameDidChangeNotification,
            object: (self.view as? NSScrollView)?.verticalRulerView,
            queue: .main
        ) { [weak self] _ in
            self?.updateTextContainerWidthIfNeeded()
            if self?.bracketPairHighlight == .flash {
                self?.removeHighlightLayers()
            }
        }

        systemAppearance = NSApp.effectiveAppearance.name

        NSApp.publisher(for: \.effectiveAppearance)
            .receive(on: RunLoop.main)
            .sink { [weak self] newValue in
                guard let self = self else { return }

                if self.systemAppearance != newValue.name {
                    self.systemAppearance = newValue.name
                }
            }
            .store(in: &cancellables)
    }

    override public func viewWillAppear() {
        super.viewWillAppear()
        updateTextContainerWidthIfNeeded(true)
    }
}
