//
//  WindowAccessor.swift
//  xHistory
//
//  Created by apple on 2024/11/7.
//

import AppKit
import SwiftUI

private final class WindowObserverView: NSView {
    var onAttach: ((NSWindow) -> Void)?
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        // one tick later, as before, so the window's content (e.g. split views) is in place
        if let window, let onAttach { self.onAttach = nil; DispatchQueue.main.async { onAttach(window) } }
    }
}

struct WindowAccessor: NSViewRepresentable {
    var onWindowOpen: ((NSWindow?) -> Void)?
    var onWindowActive: ((NSWindow?) -> Void)?
    var onWindowDeactivate: ((NSWindow?) -> Void)?
    var onWindowClose: (() -> Void)?

    func makeNSView(context: Context) -> NSView {
        // wait for the real attach: reading view.window on the next runloop tick can still be nil
        let view = WindowObserverView()
        view.onAttach = { window in
            window.delegate = context.coordinator
            context.coordinator.window = window
            self.onWindowOpen?(window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onWindowOpen: onWindowOpen,
            onWindowActive: onWindowActive,
            onWindowDeactivate: onWindowDeactivate,
            onWindowClose: onWindowClose
        )
    }

    class Coordinator: NSObject, NSWindowDelegate {
        weak var window: NSWindow? // 使用 weak 避免循环引用
        var onWindowOpen: ((NSWindow?) -> Void)?
        var onWindowActive: ((NSWindow?) -> Void)?
        var onWindowDeactivate: ((NSWindow?) -> Void)?
        var onWindowClose: (() -> Void)?

        init(onWindowOpen: ((NSWindow?) -> Void)? = nil,
             onWindowActive: ((NSWindow?) -> Void)? = nil,
             onWindowDeactivate: ((NSWindow?) -> Void)? = nil,
             onWindowClose: (() -> Void)? = nil) {
            self.onWindowOpen = onWindowOpen
            self.onWindowClose = onWindowClose
            self.onWindowActive = onWindowActive
            self.onWindowDeactivate = onWindowDeactivate
        }

        func windowWillClose(_ notification: Notification) {
            onWindowClose?()
        }
        
        func windowDidBecomeKey(_ notification: Notification) {
            onWindowActive?(window)
        }

        func windowDidResignKey(_ notification: Notification) {
            onWindowDeactivate?(window)
        }
    }
}
