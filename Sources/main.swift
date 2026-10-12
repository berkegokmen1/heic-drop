import AppKit
import UniformTypeIdentifiers

final class DropView: NSView {
    var receive: ((NSPasteboard) -> Bool)?
    override init(frame: NSRect) { super.init(frame: frame); registerForDraggedTypes([.fileURL, .tiff, .png]); wantsLayer = true; layer?.cornerRadius = 14; layer?.borderWidth = 1; layer?.borderColor = NSColor.separatorColor.cgColor }
    required init?(coder: NSCoder) { fatalError() }
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation { .copy }
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool { receive?(sender.draggingPasteboard) ?? false }
}
final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    let status = NSTextField(wrappingLabelWithString: "Drop HEIC images here")
    let detail = NSTextField(wrappingLabelWithString: "or paste with ⌘V")
    let format = NSSegmentedControl(labels: ["PNG", "JPG"], trackingMode: .selectOne, target: nil, action: nil)
    let copy = NSButton(title: "Copy", target: nil, action: nil)
    let save = NSButton(title: "Save…", target: nil, action: nil)
    var outputs: [URL] = []
    var busy = false
    let session = FileManager.default.temporaryDirectory.appendingPathComponent("HEIC-Drop-\(UUID().uuidString)")
    func applicationDidFinishLaunching(_ notification: Notification) {
        try? FileManager.default.createDirectory(at: session, withIntermediateDirectories: true)
        let menu = NSMenu(); let appItem = NSMenuItem(); menu.addItem(appItem)
        let appMenu = NSMenu(); appMenu.addItem(withTitle: "Quit HEIC Drop", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"); appItem.submenu = appMenu
        let editItem = NSMenuItem(); menu.addItem(editItem); let edit = NSMenu(title: "Edit"); edit.addItem(withTitle: "Paste", action: #selector(paste(_:)), keyEquivalent: "v"); editItem.submenu = edit
        NSApp.mainMenu = menu
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 380, height: 300), styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.title = "HEIC Drop"; window.center(); window.isReleasedWhenClosed = false
        let root = NSStackView(); root.orientation = .vertical; root.spacing = 16; root.edgeInsets = NSEdgeInsets(top: 20, left: 24, bottom: 20, right: 24)
        window.contentView = root
        format.selectedSegment = 0; root.addArrangedSubview(format)
        let drop = DropView(); drop.receive = { [weak self] in self?.receive($0) ?? false }
        let contents = NSStackView(); contents.orientation = .vertical; contents.spacing = 8; contents.translatesAutoresizingMaskIntoConstraints = false
        let icon = NSImageView(image: NSImage(systemSymbolName: "photo.on.rectangle.angled", accessibilityDescription: "Images")!); icon.contentTintColor = .controlAccentColor
        status.alignment = .center; status.font = .systemFont(ofSize: 16, weight: .medium)
        detail.alignment = .center; detail.textColor = .secondaryLabelColor; detail.font = .systemFont(ofSize: 12)
        contents.addArrangedSubview(icon); contents.addArrangedSubview(status); contents.addArrangedSubview(detail); drop.addSubview(contents)
        NSLayoutConstraint.activate([contents.centerXAnchor.constraint(equalTo: drop.centerXAnchor), contents.centerYAnchor.constraint(equalTo: drop.centerYAnchor), contents.widthAnchor.constraint(equalTo: drop.widthAnchor, constant: -24), drop.heightAnchor.constraint(equalToConstant: 150), drop.widthAnchor.constraint(equalToConstant: 332)])
        root.addArrangedSubview(drop)
        let choose = NSButton(title: "Choose…", target: self, action: #selector(chooseFiles)); copy.target = self; copy.action = #selector(copyFiles); save.target = self; save.action = #selector(saveFiles); copy.isEnabled = false; save.isEnabled = false
        let buttons = NSStackView(views: [choose, copy, save]); buttons.spacing = 12; root.addArrangedSubview(buttons)
        window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
    @objc func paste(_ sender: Any?) { _ = receive(.general) }
    @objc func chooseFiles() {
        guard !busy else { return }; let panel = NSOpenPanel(); panel.allowsMultipleSelection = true; panel.allowedContentTypes = [.image]
        panel.beginSheetModal(for: window) { [weak self] response in if response == .OK { self?.convert(panel.urls) } }
    }
    func receive(_ board: NSPasteboard) -> Bool {
        guard !busy else { return false }
        let urls = board.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? []
        if !urls.isEmpty { convert(urls); return true }
        if let image = NSImage(pasteboard: board), let data = image.tiffRepresentation {
            let url = session.appendingPathComponent("Pasted-\(UUID().uuidString).tiff")
            do { try data.write(to: url); convert([url]); return true } catch { detail.stringValue = error.localizedDescription }
        }
        return false
    }
    func convert(_ inputs: [URL]) {
        guard !busy, !inputs.isEmpty else { return }; busy = true; copy.isEnabled = false; save.isEnabled = false; format.isEnabled = false
        let chosen: OutputFormat = format.selectedSegment == 0 ? .png : .jpg
        status.stringValue = "Converting \(inputs.count) image\(inputs.count == 1 ? "" : "s")…"; detail.stringValue = "Everything stays on your Mac"
        let folder = session.appendingPathComponent(UUID().uuidString)
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            var results: [URL] = []; var failures: [String] = []
            do {
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                for input in inputs {
                    do { let output = Converter.uniqueURL(in: folder, name: input.deletingPathExtension().lastPathComponent, format: chosen); try Converter.convert(input, to: output, format: chosen); results.append(output) }
                    catch { failures.append(input.lastPathComponent) }
                }
            } catch { failures = inputs.map(\.lastPathComponent) }
            DispatchQueue.main.async { [self] in
                outputs = results; busy = false; format.isEnabled = true; copy.isEnabled = !results.isEmpty; save.isEnabled = !results.isEmpty
                status.stringValue = results.isEmpty ? "Conversion failed" : "\(results.count) \(chosen.rawValue.uppercased())\(results.count == 1 ? "" : "s") ready"
                detail.stringValue = failures.isEmpty ? "Copy or save your images • Drop more to start again" : "Could not convert: " + failures.joined(separator: ", ")
                detail.toolTip = detail.stringValue
            }
        }
    }
    @objc func copyFiles() {
        NSPasteboard.general.clearContents(); NSPasteboard.general.writeObjects(outputs as [NSURL]); detail.stringValue = "Copied \(outputs.count) file\(outputs.count == 1 ? "" : "s") • Paste into Finder or another app"
    }
    @objc func saveFiles() {
        let panel = NSOpenPanel(); panel.canChooseDirectories = true; panel.canChooseFiles = false; panel.prompt = "Save Here"; panel.canCreateDirectories = true
        panel.beginSheetModal(for: window) { [self] response in
            guard response == .OK, let directory = panel.url else { return }
            do { for output in outputs { let type = OutputFormat(rawValue: output.pathExtension)!; let target = Converter.uniqueURL(in: directory, name: output.deletingPathExtension().lastPathComponent, format: type); try FileManager.default.copyItem(at: output, to: target) }; detail.stringValue = "Saved \(outputs.count) images" }
            catch { detail.stringValue = error.localizedDescription }
        }
    }
}
let app = NSApplication.shared
let delegate = AppDelegate(); app.delegate = delegate; app.setActivationPolicy(.regular); app.run()
