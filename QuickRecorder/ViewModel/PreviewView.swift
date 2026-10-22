//
//  PreviewView.swift
//  QuickRecorder
//
//  Created by apple on 2024/12/10.
//

import SwiftUI
import Combine

struct PreviewView: View {
    let frame: NSImage
    let filePath: String
    private let sharingDelegate = SharingServicePickerDelegate()
    @State private var isHovered: Bool = false
    @State private var isHovered2: Bool = false
    @State private var isSharing: Bool = false
    @State private var nsWindow: NSWindow?
    @State private var opacity: Double = 0.0
    @AppStorage("trimAfterRecord")  private var trimAfterRecord: Bool = false
    
    var body: some View {
        // persistent card: what was saved, where, and the next steps, without having to hover to discover them
        VStack(spacing: 8) {
            ZStack {
                Image(nsImage: frame)
                    .resizable().scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .shadow(color: .black.opacity(0.2), radius: 3, y: 1.5)
                if isHovered2 {
                    Button(action: {
                        if fd.fileExists(atPath: filePath) {
                            NSWorkspace.shared.open(filePath.url)
                            closeWindow()
                        }
                    }, label: {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 44))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .black.opacity(0.5))
                            .shadow(radius: 4)
                    }).buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onHover(perform: { isHovered2 = $0 })
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 15)).foregroundStyle(.green)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Recording Completed".local).font(.system(size: 11, weight: .semibold))
                    Text(filePath.lastPathComponent).font(.system(size: 10)).foregroundStyle(.secondary)
                        .lineLimit(1).truncationMode(.middle)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 6) {
                PreviewAction(symbol: "folder", title: "Show in Finder") { showInFinder() }
                if !trimAfterRecord && ["mp4", "mov"].contains(filePath.pathExtension) {
                    PreviewAction(symbol: "scissors", title: "Trim") { trim() }
                }
                PreviewAction(symbol: "square.and.arrow.up", title: "Share") { showSharingServicePicker(for: filePath.url) }
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.regularMaterial))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(.primary.opacity(0.1)))
        .environment(\.controlActiveState, .active)
        .overlay(alignment: .topLeading) {
            if isHovered {
                Button { closeWindow() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.6))
                }
                .buttonStyle(.plain)
                .help("Close".local)
                .offset(x: -5, y: -5)
                .transition(.opacity)
            }
        }
        .padding(6) // room for the close button and stroke
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .opacity(opacity)
        .onHover(perform: { isHovered = $0 })
        .background(WindowAccessor(onWindowOpen: { w in nsWindow = w }))
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) { opacity = 1.0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                if !isHovered && !isSharing { closeWindow() }
            }
        }
        .onChange(of: isHovered) { newValue in
            if !newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    if !isHovered && !isSharing { closeWindow() }
                }
            }
        }
        .contextMenu {
            Button("Show in Finder") { showInFinder() }
            Button("Delete") {
                do {
                    try fd.removeItem(atPath: filePath)
                } catch {
                    print("Failed to delete file: \(error.localizedDescription)")
                }
                closeWindow()
            }
            Divider()
            Button("Copy") {
                if fd.fileExists(atPath: filePath) {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.writeObjects([filePath.url as NSURL])
                }
                closeWindow()
            }
            Button("Share...") { showSharingServicePicker(for: filePath.url) }
            Divider()
            if !trimAfterRecord {
                Button("Trim") { trim() }
            }
            if #available(macOS 13, *) {
                if ["mp4", "mov"].contains(filePath.pathExtension) {
                    Button("Make GIF") {
                        if isAppInstalled(id: "com.sindresorhus.Gifski") {
                            makeGif()
                            closeWindow()
                        } else {
                            let alert = createAlert(title: "Gifski not found",
                                                    message: "Please install \"Gifski\" first to make GIF!",
                                                    button1: "Open App Store", button2: "Cancel").runModal()
                            if alert == .alertFirstButtonReturn { openURL("https://apps.apple.com/app/id1351639930") }
                        }
                    }
                    Divider()
                }
            }
            Button("Close") { closeWindow() }
        }
    }
    
    func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func showInFinder() {
        if fd.fileExists(atPath: filePath) {
            NSWorkspace.shared.activateFileViewerSelecting([filePath.url])
        }
        closeWindow()
    }

    private func trim() {
        if fd.fileExists(atPath: filePath) {
            AppDelegate.shared.createNewWindow(view: VideoTrimmerView(videoURL: filePath.url), title: filePath.lastPathComponent, only: false)
        }
        closeWindow()
    }

    private func closeWindow() {
        withAnimation(.easeIn(duration: 0.2)) { opacity = 0.0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            nsWindow?.close()
        }
    }
    
    private func isAppInstalled(id: String) -> Bool {
        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) != nil
    }
    
    private func makeGif() {
        let task = Process()
        task.arguments = ["-b", "com.sindresorhus.Gifski", filePath]
        task.launchPath = "/usr/bin/open"
        task.launch()
    }
    
    private func showSharingServicePicker(for url: URL) {
        if let window = nsWindow {
            isSharing = true
            sharingDelegate.onDidChooseService = { service in
                isSharing = false
                if service != nil {
                    DispatchQueue.main.async { closeWindow() }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        if !isHovered && !isSharing { closeWindow() }
                    }
                }
            }
            let sharingPicker = NSSharingServicePicker(items: [url])
            sharingPicker.delegate = sharingDelegate
            sharingPicker.show(relativeTo: .zero, of: window.contentView!, preferredEdge: .minY)
        }
    }
}

// 自定义 NSSharingServicePickerDelegate
class SharingServicePickerDelegate: NSObject, NSSharingServicePickerDelegate {
    var onDidChooseService: ((NSSharingService?) -> Void)?
    
    func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, didChoose service: NSSharingService?) {
        onDidChooseService?(service)
    }
}

private struct PreviewAction: View {
    let symbol: String
    let title: String
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: symbol).font(.system(size: 13, weight: .medium)).frame(height: 16)
                Text(title.local).font(.system(size: 10, weight: .medium))
                    .lineLimit(1).minimumScaleFactor(0.8)
            }
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(.primary.opacity(hovering ? 0.14 : 0.07)))
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(PressStyle())
        .onHover { hovering = $0 }
    }
}
