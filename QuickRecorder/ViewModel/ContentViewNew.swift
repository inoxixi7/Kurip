//
//  ContentView.swift
//  QuickRecorder
//
//  Created by apple on 2024/4/16.
//

import SwiftUI
import AVFoundation
import ScreenCaptureKit

@available(macOS 13, *) // only shown on 13+; menuStyle(.button) needs it
struct ContentViewNew: View {
    @State private var isPopoverShowing = false
    @State private var audioPopoverShowing = false

    var horizontal = false
    var appDelegate = AppDelegate.shared
    private let columns = Array(repeating: GridItem(.fixed(104), spacing: 6), count: 3)

    var body: some View {
        ZStack {
            ZStack {
                // sized for the square panel; it would stretch the bar
                if horizontal {
                } else if isTodayChristmas() && isAllowChristmas() {
                    let images = ["snowflake1", "snowflake2", "snowflake3", "christmasTree1", "christmasTree2"]
                    SurpriseView(snowflakes: images, width: 340, height: 260, velocity: 16, lifetime: 30, alphaSpeed: -0.05)
                } else if isChineseNewYear() && isAllowChineseNewYear() {
                    let images = ["fuzi1", "fuzi2", "fuzi3", "hongbao1", "hongbao2", "hongbao3", "bianpao1", "bianpao2", "bianpao3"]
                    SurpriseView(snowflakes: images, width: 340, height: 260, velocity: 16, lifetime: 30, alphaSpeed: -0.05)
                }
            }.opacity(0.5)
            if horizontal {
                // floating bar: same tiles and controls, laid out in one row
                HStack(spacing: 12) {
                    HStack(spacing: 6) { Group { tiles }.frame(width: 92) }
                    Divider().frame(height: 64)
                    VStack(spacing: 4) {
                        FooterButton(symbol: "xmark", help: "Close") { closeMainWindow() }
                        settingsButton
                        quitButton
                    }
                }.padding(10)
            } else {
                VStack(spacing: 10) {
                    LazyVGrid(columns: columns, spacing: 6) { tiles }
                    HStack {
                        Text("Kurip").font(.system(size: 11, weight: .semibold)).foregroundStyle(.tertiary)
                        Spacer()
                        settingsButton
                        quitButton
                    }
                }
                .padding(12)
                .frame(width: 348)
            }
        }
        // the popover's clear glass lets busy windows behind it fight the labels; keep contrast steady
        .background(.regularMaterial)
    }

    @ViewBuilder private var tiles: some View {
        ModeTile(title: "Full Screen", symbol: "display") {
            closeMainWindow()
            appDelegate.createNewWindow(view: ScreenSelector(), title: "Screen Selector".local)
        }
        ModeTile(title: "Area", symbol: "rectangle.dashed") { recordArea() }
        ModeTile(title: "Windows", symbol: "macwindow") {
            closeMainWindow()
            appDelegate.createNewWindow(view: WinSelector(), title: "Window Selector".local)
        }
        ModeTile(title: "Apps", symbol: "square.on.square") {
            closeMainWindow()
            appDelegate.createNewWindow(view: AppSelector(), title: "App Selector".local)
        }
        // the audio sources only matter here; video modes set them in their own options bar
        ModeTile(title: "Audio Only", symbol: "waveform") { audioPopoverShowing = true }
            .popover(isPresented: $audioPopoverShowing, arrowEdge: .bottom) {
                AudioOnlyPopover {
                    audioPopoverShowing = false
                    if let display = SCContext.getSCDisplayWithMouse() {
                        closeMainWindow()
                        appDelegate.createCountdownPanel(screen: display) {
                            AppDelegate.shared.prepRecord(type: "audio", screens: SCContext.getSCDisplayWithMouse(), windows: nil, applications: nil)
                        }
                    }
                }
                .panelPopoverBackground()
            }
        ModeTile(title: "Device", symbol: "iphone") { isPopoverShowing = true }
            .popover(isPresented: $isPopoverShowing, arrowEdge: .bottom) {
                iDevicePopoverView(closePopover: { isPopoverShowing = false }).panelPopoverBackground()
            }
    }

    private var settingsButton: some View {
        FooterButton(symbol: "gearshape", help: "Preferences") {
            closeMainWindow()
            appDelegate.openSettingPanel()
        }
    }

    private var quitButton: some View {
        FooterButton(symbol: "power", help: "Quit") {
            let alert = createAlert(level: .informational, title: "Quit Kurip?", message: "", button1: "Quit", button2: "Cancel")
            if alert.runModal() == .alertFirstButtonReturn { NSApp.terminate(nil) }
        }
    }

    private func recordArea() {
        closeMainWindow()
        SCContext.updateAvailableContent {
            DispatchQueue.main.async {
                appDelegate.showAreaSelector(size: NSSize(width: 600, height: 450))
                var currentDisplay = SCContext.getSCDisplayWithMouse()
                mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .rightMouseDown, .leftMouseDown, .otherMouseDown]) { event in
                    let display = SCContext.getSCDisplayWithMouse()
                    if display != currentDisplay {
                        currentDisplay = display
                        closeAllWindow()
                        appDelegate.showAreaSelector(size: NSSize(width: 600, height: 450))
                    }
                }
            }
        }
    }

}

@available(macOS 13, *)
private struct AudioOnlyPopover: View {
    let onStart: () -> Void
    @State private var micList = SCContext.getMicrophone()
    @AppStorage("enableAEC") private var enableAEC: Bool = true
    @AppStorage("recordMic") private var recordMic: Bool = false
    @AppStorage("recordWinSound") private var recordWinSound: Bool = true
    @AppStorage("micDevice") private var micDevice: String = "default"

    var body: some View {
        // one column, shared edges: header with the record button, then sources, then the device
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Audio Only".local).font(.system(size: 13, weight: .semibold))
                Spacer()
                StartButton(action: onStart).disabled(!recordWinSound && !recordMic)
            }
            HStack(spacing: 6) { appAudioChip; micChip }
            HStack(spacing: 4) { devicePicker.frame(maxWidth: .infinity); aecWarning }
        }
        .padding(14)
        .frame(width: 260)
    }

    private var appAudioChip: some View {
        ToggleChip(title: "App Audio", symbol: "speaker.wave.2.fill", isOn: $recordWinSound, expand: true)
    }

    private var micChip: some View {
        ToggleChip(title: "Mic", symbol: "mic.fill", isOn: $recordMic, expand: true)
            .onChange(of: recordMic) { _ in Task { await SCContext.performMicCheck() }}
    }

    // drawn like the chips above so its edges and height match them; a stock Picker insets its bezel
    private var devicePicker: some View {
        Menu {
            micOption("Default".local, tag: "default")
            Divider()
            ForEach(micList, id: \.self) { micOption($0.localizedName, tag: $0.localizedName) }
        } label: {
            HStack {
                Text(micDevice == "default" ? "Default".local : micDevice).lineLimit(1)
                Spacer(minLength: 4)
                Image(systemName: "chevron.up.chevron.down").font(.system(size: 9, weight: .semibold))
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(recordMic ? .primary : .tertiary)
            .padding(.horizontal, 10)
            .frame(height: 24)
            .background(Capsule().fill(.primary.opacity(0.08)))
            .contentShape(Capsule())
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .disabled(!recordMic)
        .onAppear {
            if !micList.map({ $0.localizedName }).contains(micDevice) { micDevice = "default" }
        }
    }

    private func micOption(_ title: String, tag: String) -> some View {
        Toggle(title, isOn: Binding(get: { micDevice == tag }, set: { _ in micDevice = tag }))
    }

    @ViewBuilder private var aecWarning: some View {
        if micDevice != "default" && enableAEC && recordMic {
            Button { showAECWarning() } label: {
                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
            }
            .buttonStyle(.plain)
            .help("Compatibility Warning".local)
        }
    }

    private func showAECWarning() {
        let alert = createAlert(
            title: "Compatibility Warning".local,
            message: "The \"Acoustic Echo Cancellation\" is enabled, but it won't work on now.\n\nIf you need to use a specific input with AEC, set it to \"Default\" and select the device you want in System Preferences.\n\nOr you can start recording without AEC.".local,
            button1: "OK".local, button2: "System Preferences".local)
        if alert.runModal() == .alertSecondButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.sound?input")!)
        }
    }
}

private struct ModeTile: View {
    let title: String
    let symbol: String
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 24, weight: .regular))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(hovering ? Color.accentColor : .primary)
                    .frame(height: 28)
                Text(title.local)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(hovering ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 78)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(.primary.opacity(hovering ? 0.08 : 0.03)))
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(PressStyle())
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.12), value: hovering)
    }
}

// Pill toggle shared by the main panel and the recording options bar
struct ToggleChip: View {
    let title: String
    let symbol: String
    @Binding var isOn: Bool
    var expand = false // fill the row, so a pair of chips lines up with full-width controls

    var body: some View {
        Button { isOn.toggle() } label: {
            Label(title.local, systemImage: symbol)
                .fixedSize()
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isOn ? Color.white : .secondary)
                .padding(.horizontal, 9)
                .frame(maxWidth: expand ? .infinity : nil)
                .frame(height: 24)
                .background(Capsule().fill(isOn ? Color.accentColor : .primary.opacity(0.08)))
                .contentShape(Capsule())
        }
        .buttonStyle(PressStyle())
        .animation(.easeOut(duration: 0.12), value: isOn)
    }
}

private struct FooterButton: View {
    let symbol: String
    let help: String
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(hovering ? .primary : .secondary)
                .frame(width: 26, height: 22)
                .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(.primary.opacity(hovering ? 0.08 : 0)))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .help(help.local)
    }
}

extension View {
    // fill the popover, arrow included, with the panel's material so both read as one surface
    func panelPopoverBackground() -> some View {
        background(Rectangle().fill(.regularMaterial).padding(-40))
    }
}

struct PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}
