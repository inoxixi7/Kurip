//
//  BundleSelector.swift
//  QuickRecorder
//
//  Created by apple on 2024/4/28.
//

import SwiftUI
import Foundation

struct BundleSelector: View {
    @State private var Bundles = [AppInfo]()
    @State private var isShowingFilePicker = false
    @Environment(\.nativeForm) private var nativeForm

    var body: some View {
        Group {
            if nativeForm { formRows } else { legacyList }
        }
        .onAppear {
            if let savedData = ud.data(forKey: "hiddenApps"),
               let decodedApps = try? JSONDecoder().decode([AppInfo].self, from: savedData) {
                Bundles = decodedApps
            }
        }
        .onChange(of: Bundles) { bundles in
            if let encodedData = try? JSONEncoder().encode(bundles) {
                ud.set(encodedData, forKey: "hiddenApps")
            }
        }
        .fileImporter(isPresented: $isShowingFilePicker, allowedContentTypes: [.application]) { result in
            do {
                guard let appID = try Bundle(url: result.get())?.bundleIdentifier else { return }
                guard let displayName = try Bundle(url: result.get())?.fileName else { return }
                let app = AppInfo(bundleID: appID, displayName: displayName)
                if !self.Bundles.contains(app) {
                    withAnimation { Bundles.append(app) }
                }
            } catch {
                print("File selection failed: \(error.localizedDescription)")
            }
        }
    }

    // rows like the app lists in System Settings: icon, name, remove; add at the end
    @ViewBuilder private var formRows: some View {
        ForEach(Bundles, id: \.self) { item in
            HStack(spacing: 8) {
                Image(nsImage: icon(for: item)).resizable().frame(width: 20, height: 20)
                Text((item.displayName as NSString).deletingPathExtension)
                Spacer()
                Button { _ = withAnimation { Bundles.removeAll { $0 == item } } } label: {
                    Image(systemName: "minus.circle")
                }
                .buttonStyle(.borderless)
                .help("Delete".local)
            }
        }
        Button { isShowingFilePicker = true } label: { Label("Add App…".local, systemImage: "plus") }
            .buttonStyle(.borderless)
    }

    private func icon(for app: AppInfo) -> NSImage {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleID) {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        return NSWorkspace.shared.icon(for: .application)
    }

    private var legacyList: some View {
        ZStack(alignment: Alignment(horizontal: .trailing, vertical: .bottom)) {
            List(Bundles, id: \.self) { item in
                HStack{
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.red)
                        .onTapGesture {
                            if let index = Bundles.firstIndex(of: item) {
                                _ = withAnimation { Bundles.remove(at: index) }
                            }
                        }
                    Text(item.displayName).font(.system(size: 12))
                }
            }
            Button(action: {
                self.isShowingFilePicker = true
            }) {
                Image(systemName: "plus.square.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)
            }.buttonStyle(.plain).offset(y: -1)
        }
    }
}

struct AppInfo: Hashable, Codable {
    let bundleID: String
    let displayName: String

}

extension Bundle {
    var bundleName: String? { return object(forInfoDictionaryKey: "CFBundleName") as? String }
    var fileName: String { return self.bundleURL.lastPathComponent }
}
