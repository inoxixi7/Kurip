//
//  AppSelector.swift
//  QuickRecorder
//
//  Created by apple on 2024/4/16.
//

import SwiftUI
import Combine
import ScreenCaptureKit

struct AppSelector: View {
    @StateObject var viewModel = AppSelectorViewModel()
    @State private var selected = [SCRunningApplication]()
    @State private var display: SCDisplay!
    @State private var selectedTab = 0
    @State private var autoStop = 0
    var appDelegate = AppDelegate.shared
    
    var body: some View {
        ZStack {
            VStack(spacing: 15) {
                if #available(macOS 15, *) {
                    Text("Please select the App(s) to record").offset(y: 12)
                } else {
                    Text("Please select the App(s) to record")
                }
                TabView(selection: $selectedTab) {
                    let allApps = viewModel.allApps.sorted(by: { $0.key.displayID < $1.key.displayID })
                    ForEach(allApps, id: \.key) { element in
                        let (screen, apps) = element
                        let index = allApps.firstIndex(where: { $0.key == screen }) ?? 0
                        ScrollView(.vertical) {
                            VStack(spacing: 8) {
                                ForEach(0..<apps.count/5 + 1, id: \.self) { rowIndex in
                                    HStack(spacing: 20) {
                                        ForEach(0..<5, id: \.self) { columnIndex in
                                            let index = 5 * rowIndex + columnIndex
                                            if index <= apps.count - 1 {
                                                let item = apps[index]
                                                Button(action: {
                                                    if !selected.contains(item) {
                                                        selected.append(item)
                                                    } else {
                                                        selected.removeAll{ $0 == item }
                                                    }
                                                }, label: {
                                                    ZStack {
                                                        VStack {
                                                            Image(nsImage: SCContext.getAppIcon(item)!)
                                                            let appName = item.applicationName
                                                            let appID = item.bundleIdentifier
                                                            Text(appName != "" ? appName : appID)
                                                                .foregroundStyle(.secondary)
                                                                .lineLimit(1)
                                                                .truncationMode(.tail)
                                                        }
                                                        .frame(width: 110, height: 94)
                                                        .padding(10)
                                                        .background(
                                                            Rectangle()
                                                                .foregroundStyle(.blue)
                                                                .cornerRadius(5)
                                                                .opacity(selected.contains(item) ? 0.2 : 0.0)
                                                        )
                                                        Image(systemName: "circle.fill")
                                                            .font(.system(size: 31))
                                                            .foregroundStyle(.white)
                                                            .opacity(selected.contains(item) ? 1.0 : 0.0)
                                                            .offset(x: 20, y: 10)
                                                        Image(systemName: "checkmark.circle.fill")
                                                            .font(.system(size: 27))
                                                            .foregroundStyle(.green)
                                                            .opacity(selected.contains(item) ? 1.0 : 0.0)
                                                            .offset(x: 20, y: 10)
                                                    }
                                                }).buttonStyle(.plain)
                                            }
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 12).padding(.top, 4)
                                }
                            }
                        }
                        .tag(index)
                        .tabItem { Text(screen.nsScreen?.localizedName ?? ("Display ".local + "\(index)")) }
                        .onAppear{ display = screen }
                    }
                }
                .frame(height: 445)
                .padding(.horizontal, 10)
                .onChange(of: selectedTab) { _ in selected.removeAll() }
                .onReceive(viewModel.$isReady) { isReady in
                    if isReady {
                        let allApps = viewModel.allApps.sorted(by: { $0.key.displayID < $1.key.displayID })
                        if let s = NSApp.windows.first(where: { $0.title == "App Selector".local })?.screen,
                           let index = allApps.firstIndex(where: { $0.key.displayID == s.displayID }) {
                            selectedTab = index
                        }
                    }
                }
                HStack(spacing: 10) {
                    ToolbarButton(symbol: "arrow.clockwise", title: "Refresh".local) { viewModel.updateAppList() }
                    // spare width is shared around the dividers, not dumped before the buttons
                    Spacer(minLength: 0)
                    Divider().frame(height: 40)
                    Spacer(minLength: 0)
                    OptionsView()
                    Spacer(minLength: 0)
                    Divider().frame(height: 40)
                    Spacer(minLength: 0)
                    TimerButton(autoStop: $autoStop)
                    StartButton { startRecording() }.disabled(selected.isEmpty)
                }
                .padding(.leading, 24).padding(.trailing, 36)
                .frame(height: 76)
                Spacer()
            }.padding(.top, -5)
        }.frame(width: 780, height:555)
    }
    
    func startRecording() {
        closeAllWindow()
        appDelegate.createCountdownPanel(screen: display) {
            SCContext.autoStop = autoStop
            appDelegate.prepRecord(type: "application", screens: display, windows: nil, applications: selected)
        }
    }
}

class AppSelectorViewModel: ObservableObject {
    @Published var allApps = [SCDisplay: [SCRunningApplication]]()
    @Published var isReady = false
    
    init() {
        updateAppList()
    }
    
    func updateAppList() {
        SCContext.updateAvailableContent {
            guard let screens = SCContext.availableContent?.displays else { return }
            for screen in screens {
                var apps = [SCRunningApplication]()
                let windows = SCContext.getWindows().filter({ NSIntersectsRect(screen.frame, $0.frame) })
                for app in windows.map({ $0.owningApplication }) { if !apps.contains(app!) { apps.append(app!) }}
                if ud.bool(forKey: "hideSelf") { apps = apps.filter({$0.bundleIdentifier != Bundle.main.bundleIdentifier}) }
                DispatchQueue.main.async { self.allApps[screen] = apps }
            }
            DispatchQueue.main.async { self.isReady = true }
        }
    }
    
    /*func updateAppList() {
        SCContext.updateAvailableContent{
            DispatchQueue.main.async {
                self.allApps = SCContext.getApps().filter({ $0.bundleIdentifier != Bundle.main.bundleIdentifier })
            }
        }
    }*/
}

struct OptionsView: View {
    @State private var micList = SCContext.getMicrophone()
    
    @AppStorage("frameRate")      private var frameRate: Int = 60
    @AppStorage("videoQuality")   private var videoQuality: Double = 1.0
    @AppStorage("saveDirectory")  private var saveDirectory: String?
    @AppStorage("hideSelf")       private var hideSelf: Bool = false
    @AppStorage("showMouse")      private var showMouse: Bool = true
    @AppStorage("recordMic")      private var recordMic: Bool = false
    @AppStorage("recordWinSound") private var recordWinSound: Bool = true
    @AppStorage("background")     private var background: BackgroundType = .wallpaper
    @AppStorage("highRes")        private var highRes: Int = 2
    @AppStorage("recordHDR")      private var recordHDR: Bool = false
    @AppStorage("micDevice")      private var micDevice: String = "default"
    @AppStorage("enableAEC")      private var enableAEC: Bool = true
    
    private let rowHeight: CGFloat = 24 // = ToggleChip height
    private let rowSpacing: CGFloat = 6

    var body: some View {
        HStack(spacing: 14) {
            HStack(spacing: 6) {
                // trailing labels sit right next to their values, however long the longest one is
                VStack(alignment: .trailing, spacing: rowSpacing) {
                    OptionLabel("Resolution")
                    OptionLabel("Frame Rate")
                }
                VStack(alignment: .leading, spacing: rowSpacing) {
                    Picker("", selection: $highRes) {
                        Text("High (auto)").tag(2)
                        Text("Normal (1x)").tag(1)
                    }.frame(height: rowHeight)
                    Picker("", selection: $frameRate) {
                        if ![240, 144, 120, 90, 60, 30, 24, 15 ,10].contains(frameRate) {
                            Text("\(frameRate) FPS").tag(frameRate)
                        }
                        ForEach([240, 144, 120, 90, 60, 30, 24, 15, 10], id: \.self) { Text("\($0) FPS").tag($0) }
                    }.frame(height: rowHeight)
                }
                VStack(alignment: .trailing, spacing: rowSpacing) {
                    OptionLabel("Quality")
                    OptionLabel("Background")
                }.padding(.leading, 8)
                VStack(alignment: .leading, spacing: rowSpacing) {
                    Picker("", selection: $videoQuality) {
                        Text("High").tag(1.0)
                        Text("Medium").tag(0.7)
                        Text("Low").tag(0.3)
                    }.frame(height: rowHeight)
                    Picker("", selection: $background) {
                        Text("Wallpaper").tag(BackgroundType.wallpaper)
                        if ud.bool(forKey: "withAlpha") { Text("Transparent").tag(BackgroundType.clear) }
                        Text("Black").tag(BackgroundType.black)
                        Text("White").tag(BackgroundType.white)
                        Text("Gray").tag(BackgroundType.gray)
                        Text("Yellow").tag(BackgroundType.yellow)
                        Text("Orange").tag(BackgroundType.orange)
                        Text("Green").tag(BackgroundType.green)
                        Text("Blue").tag(BackgroundType.blue)
                        Text("Red").tag(BackgroundType.red)
                        Text("Custom").tag(BackgroundType.custom)
                    }.frame(height: rowHeight)
                }
            }
            .labelsHidden()
            .buttonStyle(.borderless)
            .fixedSize()
            Divider().frame(height: 44)
            VStack(alignment: .leading, spacing: rowSpacing) {
                HStack(spacing: 6) {
                    if #available(macOS 15, *) {
                        ToggleChip(title: "HDR", symbol: "sparkles", isOn: $recordHDR).help("Record HDR".local)
                    }
                    ToggleChip(title: "Cursor", symbol: "cursorarrow", isOn: $showMouse).help("Record Cursor".local)
                }
                HStack(spacing: 6) {
                    if #available(macOS 13, *) {
                        ToggleChip(title: "App Audio", symbol: "speaker.wave.2.fill", isOn: $recordWinSound).help("App's Audio".local)
                    }
                    micChip
                }
            }
        }
        .onAppear {
            if micList.isEmpty { recordMic = false }
            if !micList.map({ $0.localizedName }).contains(micDevice) { micDevice = "default" }
        }
    }

    // split button: the left half toggles the mic, the chevron picks the device
    private func micOption(_ title: String, tag: String) -> some View {
        Toggle(title, isOn: Binding(get: { micDevice == tag }, set: { _ in micDevice = tag }))
    }

    private var micChip: some View {
        HStack(spacing: 4) {
            ToggleChip(title: "Mic", symbol: "mic.fill", isOn: $recordMic)
                .disabled(micList.isEmpty)
                .onChange(of: recordMic) { _ in Task { await SCContext.performMicCheck() }}
            Menu {
                micOption("Default".local, tag: "default")
                Divider()
                ForEach(micList, id: \.self) { micOption($0.localizedName, tag: $0.localizedName) }
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .frame(width: 20, height: rowHeight)
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .disabled(!recordMic)
            .help(micDevice == "default" ? "Default".local : micDevice)
            if micDevice != "default" && enableAEC && recordMic {
                Button(action: {
                    let alert = createAlert(
                        title: "Compatibility Warning".local,
                        message: "The \"Acoustic Echo Cancellation\" is enabled, but it won't work on now.\n\nIf you need to use a specific input with AEC, set it to \"Default\" and select the device you want in System Preferences.\n\nOr you can start recording without AEC.".local,
                        button1: "OK".local, button2: "System Preferences".local)
                    if alert.runModal() == .alertSecondButtonReturn {
                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.sound?input")!)
                    }
                }, label: {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                })
                .buttonStyle(.plain)
                .help("Compatibility Warning".local)
            }
        }
    }
}

private struct OptionLabel: View {
    let key: LocalizedStringKey
    init(_ key: LocalizedStringKey) { self.key = key }
    var body: some View {
        Text(key).font(.system(size: 12)).foregroundStyle(.secondary).frame(height: 24)
    }
}
