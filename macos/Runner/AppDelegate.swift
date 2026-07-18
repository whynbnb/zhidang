import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  /// Re-assert key window / first responder so macOS IME (e.g. Pinyin) works
  /// after cold start or returning from another app.
  override func applicationDidBecomeActive(_ notification: Notification) {
    super.applicationDidBecomeActive(notification)
    guard let window = NSApp.mainWindow ?? NSApp.keyWindow else { return }
    window.makeKeyAndOrderFront(nil)
    if let content = window.contentViewController?.view {
      window.makeFirstResponder(content)
    }
  }
}
