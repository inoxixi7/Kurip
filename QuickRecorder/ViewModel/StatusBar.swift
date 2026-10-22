//
//  StatusBarItem.swift
//  QuickRecorder
//
//  Created by apple on 2024/4/16.
//

import SwiftUI

class PopoverState: ObservableObject {
    static let shared = PopoverState()
    @Published var isShowing: Bool = false
    @Published var isPaused: Bool = false
}

// Floating recording controller, shown in `controlPanel` when the menu bar hides the status item.
struct StatusBarItem: View {
    @State private var deviceWindowIsShowing = true
    @State private var isHovering = false
    @State private var recordingLength = "00:00"
    @StateObject private var popoverState = PopoverState.shared
    @AppStorage("miniStatusBar") private var miniStatusBar: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            if SCContext.streamType != nil {
                ZStack {
                    Rectangle()
                        .fill(Color.mypurple)
                        .shadow(color: .black.opacity(0.3), radius: 4)
                        .cornerRadius(4)
                    HStack(spacing: 4) {
                        if miniStatusBar {
                            if isHovering {
                                Button(action: {
                                    StatusBarController.shared.stop()
                                }, label: {
                                    ZStack {
                                        Image(systemName: "circle.fill")
                                            .font(.system(size: 10))
                                            .foregroundStyle(.red)
                                            .frame(width: 10, alignment: .center)
                                        Image(systemName: "stop.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(.white)
                                            .frame(width: 16, alignment: .center)
                                    }
                                }).buttonStyle(.plain)
                                if SCContext.streamType != .idevice {
                                    Button(action: {
                                        SCContext.pauseRecording()
                                    }, label: {
                                        Image(systemName: popoverState.isPaused ? "play.circle.fill" : "pause.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(.white)
                                            .frame(width: 16, alignment: .center)
                                    }).buttonStyle(.plain)
                                } else {
                                    Button(action:{
                                        DispatchQueue.main.async {
                                            if deviceWindow.isVisible { deviceWindow.close() } else { deviceWindow.orderFront(nil) }
                                            deviceWindowIsShowing = deviceWindow.isVisible
                                        }
                                    }, label: {
                                        Image(systemName: "eye.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(.white)
                                            .frame(width: 16, alignment: .center)
                                            .opacity(deviceWindowIsShowing ? 1 : 0.7)
                                    }).buttonStyle(.plain)
                                }
                                if SCContext.streamType != .systemaudio && SCContext.streamType != .idevice && SCContext.streamType != .window {
                                    Button(action:{
                                        popoverState.isShowing = true
                                    }, label: {
                                        Image(systemName: "camera.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(.white)
                                            .frame(width: 16, alignment: .center)
                                    }).buttonStyle(.plain)
                                }
                            } else {
                                Text(recordingLength)
                                    .foregroundStyle(.white)
                                    .font(.system(size: 15).monospaced())
                                    .offset(x: 0.5)
                            }
                        } else {
                            Group {
                                Button(action: {
                                    StatusBarController.shared.stop()
                                }, label: {
                                    ZStack {
                                        Image(systemName: "circle.fill")
                                            .font(.system(size: 10))
                                            .foregroundStyle(.red)
                                            .frame(width: 10, alignment: .center)
                                        Image(systemName: "stop.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(.white)
                                            .frame(width: 16, alignment: .center)
                                    }
                                }).buttonStyle(.plain)
                                if SCContext.streamType != .idevice {
                                    Button(action: {
                                        SCContext.pauseRecording()
                                    }, label: {
                                        Image(systemName: popoverState.isPaused ? "play.circle.fill" : "pause.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(.white)
                                            .frame(width: 16, alignment: .center)
                                    }).buttonStyle(.plain)
                                }
                                Text(recordingLength)
                                    .foregroundStyle(.white)
                                    .font(.system(size: 15).monospaced())
                                    .offset(x: 0.5)
                            }
                        }
                    }
                }
                .padding([.leading,.trailing], 4)
                .popover(isPresented: $popoverState.isShowing, arrowEdge: .bottom) {
                    CameraPopoverView(closePopover: { popoverState.isShowing = false })
                }
                .onReceive(updateTimer) { _ in recordingLength = SCContext.getRecordingLength() }
                if !miniStatusBar {
                    if SCContext.streamType != .systemaudio {
                        if SCContext.streamType != .idevice {
                            Button(action:{
                                popoverState.isShowing = true
                            }, label: {
                                ZStack {
                                    Rectangle()
                                        .fill(SCContext.isCameraRunning() ? Color.mygreen : .gray)
                                        .shadow(color: .black.opacity(0.3), radius: 4)
                                        .cornerRadius(4)
                                    Image("camera")
                                        .foregroundStyle(.white)
                                }.frame(width: 36).padding([.leading,.trailing], 4)
                            }).buttonStyle(.plain)
                        } else {
                            Button(action:{
                                DispatchQueue.main.async {
                                    if deviceWindow.isVisible { deviceWindow.close() } else { deviceWindow.orderFront(nil) }
                                }
                            }, label: {
                                ZStack {
                                    Rectangle()
                                        .fill(deviceWindow.isVisible ? Color.myblue : .gray.opacity(0.7))
                                        .shadow(color: .black.opacity(0.3), radius: 4)
                                        .cornerRadius(4)
                                    Image(systemName: "apps.ipad")
                                        .font(.system(size: 16))
                                        .foregroundStyle(.white)
                                }.frame(width: 36).padding([.leading,.trailing], 4)
                            })
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .onTapGesture {}
        .onHover { hovering in
            isHovering = hovering
            hideMousePointer = hovering
            hideScreenMagnifier = hovering
        }
    }
}

// Native status item: SwiftUI controls hosted inside NSStatusBarButton no longer receive clicks
// on recent macOS menu bars, so clicks go through the button's action and a standard NSMenu.
final class StatusBarController: NSObject {
    static let shared = StatusBarController()
    let popover: NSPopover = {
        let popover = NSPopover()
        popover.behavior = .transient
        return popover
    }()
    private var timer: Timer?

    func update() {
        guard let button = statusBarItem.button else { return }
        button.subviews.forEach { $0.removeFromSuperview() }
        button.target = self
        button.action = #selector(clicked)
        button.imagePosition = .imageLeading
        button.font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .medium)
        button.setAccessibilityLabel("Kurip")
        if SCContext.streamType != nil {
            popover.performClose(nil)
            if timer == nil {
                let t = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in self?.tick() }
                RunLoop.main.add(t, forMode: .common)
                timer = t
            }
            tick()
            statusBarItem.isVisible = true
        } else {
            timer?.invalidate()
            timer = nil
            button.title = ""
            button.image = NSImage(systemSymbolName: "dot.circle.and.hand.point.up.left.fill", accessibilityDescription: "Kurip")
            statusBarItem.isVisible = ud.bool(forKey: "showMenubar")
        }
    }

    private func tick() {
        guard SCContext.streamType != nil, let button = statusBarItem.button else { return }
        let symbol = SCContext.isPaused ? "pause.circle.fill" : "record.circle"
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?
            .withSymbolConfiguration(.init(paletteColors: [SCContext.isPaused ? .systemOrange : .systemRed]))
        button.title = " " + SCContext.getRecordingLength()

        if let start = SCContext.startTime, SCContext.autoStop != 0,
           Date.now.timeIntervalSince(start) / 60 >= Double(SCContext.autoStop) { stop(); return }

        guard let visible = button.window?.occlusionState.contains(.visible) else { return }
        if visible { controlPanel.close(); return }
        if !controlPanel.isVisible, let screen = SCContext.getScreenWithMouse() {
            let width = getStatusBarWidth()
            let contentView = NSHostingView(rootView: StatusBarItem())
            contentView.frame = NSRect(x: (screen.frame.width - width) / 2, y: screen.visibleFrame.maxY, width: width, height: 24)
            controlPanel.setFrame(contentView.frame, display: true)
            controlPanel.contentView = contentView
            controlPanel.makeKeyAndOrderFront(nil)
        }
    }

    func stop() {
        if SCContext.streamType == .idevice { AVOutputClass.shared.stopRecording() } else { SCContext.stopRecording() }
    }

    @objc private func clicked() {
        guard let button = statusBarItem.button else { return }
        guard let type = SCContext.streamType else {
            if popover.isShown { popover.performClose(nil); return }
            if #available(macOS 13, *) {
                showPopover(ContentViewNew().onAppear { closeAllWindow() })
            } else {
                showPopover(ContentView(fromStatusBar: true).onAppear {
                    closeAllWindow()
                    NSApp.activate(ignoringOtherApps: true)
                })
            }
            return
        }
        let menu = NSMenu()
        menu.addItem(item("Stop Recording", symbol: "stop.circle") { [weak self] in self?.stop() })
        if type != .idevice {
            menu.addItem(item("Pause / Resume", symbol: SCContext.isPaused ? "play.circle" : "pause.circle") { [weak self] in
                SCContext.pauseRecording()
                self?.tick()
            })
        }
        if type == .idevice {
            menu.addItem(item("Show / Hide Device Window", symbol: "apps.ipad") {
                if deviceWindow.isVisible { deviceWindow.close() } else { deviceWindow.orderFront(nil) }
            })
        } else if type != .systemaudio {
            menu.addItem(.separator())
            let cam = item("Camera Overlay…", symbol: "camera") { [weak self] in
                self?.showPopover(CameraPopoverView(closePopover: { self?.popover.performClose(nil) }))
            }
            cam.state = SCContext.isCameraRunning() ? .on : .off
            menu.addItem(cam)
        }
        statusBarItem.menu = menu
        button.performClick(nil)
        statusBarItem.menu = nil
    }

    private func showPopover<V: View>(_ view: V) {
        guard let button = statusBarItem.button else { return }
        popover.contentViewController = NSHostingController(rootView: view)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    private func item(_ title: String, symbol: String, action: @escaping () -> Void) -> NSMenuItem {
        let item = ClosureMenuItem(title: title.local, action: action)
        item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        return item
    }
}

private final class ClosureMenuItem: NSMenuItem {
    private let handler: () -> Void
    init(title: String, action: @escaping () -> Void) {
        handler = action
        super.init(title: title, action: #selector(run), keyEquivalent: "")
        target = self
    }
    required init(coder: NSCoder) { fatalError() }
    @objc private func run() { handler() }
}

func updateStatusBar() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { StatusBarController.shared.update() }
}
