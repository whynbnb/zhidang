import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // Keep desktop layout usable on narrow windows.
    self.minSize = NSSize(width: 560, height: 420)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()

    // Chinese / other IME input needs the Flutter view as first responder.
    // Without this, the first focused TextField may not receive marked text
    // until the window is re-activated or the field is re-tapped.
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.makeKeyAndOrderFront(nil)
      self.makeFirstResponder(flutterViewController.view)
    }
  }

  override var canBecomeKey: Bool { true }

  override var canBecomeMain: Bool { true }
}
